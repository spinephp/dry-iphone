//
//  ViewController.swift
//  Dring
//
//  Created by 刘兴明 on 16/01/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import UIKit
import CoreData
import AudioToolbox

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

var touchPoint = CGPoint(x:0,y:0)
var timerCount = 0

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,UIScrollViewDelegate{
    var vmPicker:UIView!
    static var lbLoading:UILabel!
    static var lbSettingTemperature:UILabel?
    static var lbTemperature:UILabel?
    static var lbSettingVelocity:UILabel?
    static var lbRealVelocity:UILabel?
    static var lbLineTime:UILabel?
    static var lbRunTime:UILabel?
    static var lbStatus:UILabel?
    static var lbLineStatus:UILabel?
    static var isWiatDry:Bool = true
    static var timer:DispatchSourceTimer?
    static var timer1:DispatchSourceTimer?
    var pickerView: UIPickerView!
    var scrollView: UIScrollView!
    var btnPicker: UIButton!
    var scales = ["默认","20 分钟","30 分钟","1 小时","2 小时","3 小时","4 小时","5 小时","6 小时","7 小时","8 小时"]
    var dryingRecord:[Dictionary<String, Any>] = []
    var valuePicker:Int = 0
    var scrollPos:CGFloat = 0.0
    var scrollStartPoint:CGPoint!
    var viewBounds:CGRect!
    static var temperatureDatas:NSMutableArray = []
    static var currentLineNo:Int = 0
    static var lineStartTime:[Int] = [0]
    static var lineTime:[Int] = [0]
    static var lineEndTemperature:[Int] = [0]
    static var isPlaying:Bool = false
    static var playingSoundID:UInt32 = 0

    /**
     * 取数据库上下文
     * @param
     *    none
     * @return
     *     NSManagedObjectContext，指定数据库上下文
     */
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    /**
     * 长按手势，绘制温度查看线
     * @param
     *    sender - UILongPressGestureRecognizer 类型，指定触发事件
     * @return
     *     none
     */
    func handleLongpressGesture(sender : UILongPressGestureRecognizer){
        
        let point:CGPoint = sender.location(in: self.view)
        var time:Int = -1
        if sender.state == UIGestureRecognizerState.began{
            time = Draw.drawSeeLine(x: point.x)
        }else if sender.state == UIGestureRecognizerState.ended{
            Draw.removeSeeLine(x: point.x)
        }else if sender.state == UIGestureRecognizerState.changed{
            Draw.removeSeeLine(x: point.x)
            time = Draw.drawSeeLine(x: point.x)
        }
        
        // 查找干燥数据中与 time 相对应的记录，并显示该记录的参数和状态
        if time != -1 && ViewController.temperatureDatas.count>0{
            for rec in ViewController.temperatureDatas{
                let r = rec as! Dictionary<String, Any>
                let time1 = r["time"] as! Int
                if time1 >= time{
                    showDryData(rec:r) // show dry paramters and status
                    break
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //支持多点触摸
        self.view.isMultipleTouchEnabled = true
        
        // 长按手势,显示查看线
        var longpressGesutre = UILongPressGestureRecognizer(target: self, action:#selector(handleLongpressGesture))
        //长按时间为1秒
        longpressGesutre.minimumPressDuration = 1
        //允许15秒运动
        longpressGesutre.allowableMovement = 15
        //所需触摸1次
        longpressGesutre.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(longpressGesutre)
        
        // Do any additional setup after loading the view, typically from a nib.
        Draw.view = self.view
        
        //获取屏幕大小（不包括状态栏高度）
        viewBounds = CGRect(x:0,y:20,
                            width:UIScreen.main.bounds.width,
                            height:UIScreen.main.bounds.height-20)
        let textY = UIScreen.main.bounds.height-57
        Draw.vCoord(rect: viewBounds)
        Draw.grad(dx:0,rect: viewBounds)
        Draw.frame(x:6,y:textY,width:132,height:55,stringWidth:65)
        Draw.frame(x:144,y:textY,width:200,height:55,stringWidth:35)
        Draw.frame(x:350,y:textY,width:126,height:55,stringWidth:35)
        
        scrollView = UIScrollView(frame:viewBounds)
        
        if let theScrollView = scrollView{
            theScrollView.contentSize=CGSize(width:CGFloat(96*60*6), height:CGFloat(UIScreen.main.bounds.height))
            theScrollView.delegate = self
            self.view.addSubview(theScrollView)
        }
        
        //DataController(name: "DryMain",classname:nil).fetch(params: nil)
        
        // 远程获得干燥记录数据
        let drymain = DataController(name: "DryMain")
        let param = ["filter": drymain.attributes()] as [String : Any]
        Network.request(method: "GET", url: drymain.url(), params: param, success: {(result) in
            //首先判断能不能转换
            self.dryingRecord.removeAll()
            for item in result!{
                self.dryingRecord.append(item)
                if (item["state"] as! Int)==0{
                    ViewController.isWiatDry = false
                }
            }
            ViewController.lbSettingTemperature = self.view.viewWithTag(1) as! UILabel?
            ViewController.lbTemperature = self.view.viewWithTag(2) as! UILabel?
            ViewController.lbSettingVelocity = self.view.viewWithTag(3) as! UILabel?
            ViewController.lbRealVelocity = self.view.viewWithTag(4) as! UILabel?
            ViewController.lbLineTime = self.view.viewWithTag(7) as! UILabel?
            ViewController.lbRunTime = self.view.viewWithTag(8) as! UILabel?
            ViewController.lbLineStatus = self.view.viewWithTag(5) as! UILabel?
            ViewController.lbStatus = self.view.viewWithTag(6) as! UILabel?
            let btn = self.view.viewWithTag(101) as! UIButton
            let s = ((result?.count)!>0) ? "请选择干燥记录" : "无"
            btn.setTitle(s, for: .normal)
            btn.isEnabled = (result?.count)!>0
        }, failure: {(error) in
            print(error)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     * 创建一个选择框
     * @param
     *    title - UString 类型，指定标题
     * @return
     *     Void
     */
    func createPickerview(title:String) -> Void {
        vmPicker = UIView(frame: CGRect(x:0, y:0, width:300, height:200))
        vmPicker.center = self.view.center
        vmPicker.backgroundColor = UIColor.init(red: 0.8, green: 0.8, blue:0.8, alpha: 1.0)
        
        pickerView = UIPickerView(frame: CGRect(x:3, y:33, width:294, height:164))
        //pickerView.center = vmPicker.center
        print(pickerView)
        pickerView.backgroundColor = UIColor.white
        
        //将dataSource设置成自己
        pickerView.dataSource = self
        //将delegate设置成自己
        pickerView.delegate = self
        //设置选择框的默认值
        pickerView.selectRow(valuePicker,inComponent:0,animated:true)
        
        //建立一个按钮，触摸按钮时获得选择框被选择的索引
        let label = UILabel(frame:CGRect(x:65, y:2, width:170, height:29))
        label.backgroundColor = UIColor.lightText
        label.textAlignment = .center
        label.text = title
        
        //建立一个按钮，触摸按钮时获得选择框被选择的索引
        let button = UIButton(frame:CGRect(x:237, y:2, width:60, height:29))
        button.backgroundColor = UIColor.lightGray
        button.setTitle("完成",for:.normal)
        button.addTarget(self, action:#selector(ViewController.getPickerViewValue),
                         for: .touchUpInside)
        
        //建立一个按钮，触摸按钮时获得选择框被选择的索引
        let btnCancel = UIButton(frame:CGRect(x:3, y:2, width:60, height:29))
        btnCancel.backgroundColor = UIColor.lightGray
        btnCancel.setTitle("取消",for:.normal)
        btnCancel.addTarget(self, action:#selector(ViewController.cancelPickerViewValue),
                            for: .touchUpInside)
        
        vmPicker.addSubview(label)
        vmPicker.addSubview(button)
        vmPicker.addSubview(btnCancel)
        vmPicker.addSubview(pickerView)
        self.view.addSubview(vmPicker)
    }
    
    /**
     * 根据指定的按键和标题，创建一个选择框
     * @param
     *    btn - UIButton 类型，指定触发的按键
     *    title - UString 类型，指定标题
     * @return
     *     Void
     */
    func createPickByBtn(btn:UIButton,title:String)->Void{
        btnPicker = btn
        if btn.isEnabled{
            setButtonsEnabled(enabled:false)
            createPickerview(title:title)
        }
    }
    
    /**
     * 时间单位按键 touch up inside 事件处理程序
     * @param
     *    title - UString 类型，指定标题
     * @return
     *     Void
     */
    @IBAction func scale(_ sender: UIButton) {
        createPickByBtn(btn:sender,title:"设置时间单位")
    }
    
    /**
     * 干燥曲线按键 touch up inside 事件处理程序
     * @param
     *    sender - UIButton 类型，指定触发的按键
     * @return
     *     Void
     */
    @IBAction func dryingDate(_ sender: UIButton) {
        createPickByBtn(btn:sender,title:"选择干燥记录")
    }
    
    /**
     * 设置选择框的列数为1列,继承于UIPickerViewDataSource协议
     * @param
     *    pickerView - UIPickerView 类型，指定选择框
     * @return
     *     Int, 指定选择框的列数
     */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /**
     * 设置选择框的行数,继承于UIPickerViewDataSource协议
     * @param
     *    pickerView - UIPickerView 类型，指定选择框
     *    component - Int 类型，指定组件行数
     * @return
     *     Int, 指定选择框的行数
     */
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        var result = 0
        if btnPicker.tag == 100{
            result = scales.count
        }
        else if btnPicker.tag==101 {
            result = dryingRecord.count
            if ViewController.isWiatDry{
                result += 1
            }
        }
        return result
    }
    
    /**
     * 设置选择框各选项的内容,继承于UIPickerViewDataSource协议
     * @param
     *    pickerView - UIPickerView 类型，指定选择框
     *    component - Int 类型，指定组件行数
     *    row - Int 类型，指定选择框行的索引
     * @return
     *     String?, 包含选择框对应行索引 row 的字符串
     */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        var result:String?
        if btnPicker.tag == 100{
            result = scales[row]
        }
        else if btnPicker.tag==101 {
            if row < dryingRecord.count{
            var state:Int = -1
            for item in dryingRecord[row]{
                if item.key=="starttime"{
                    result = (item.value  as? String)!
                }else if item.key=="state"{
                    state = item.value as! Int
                }
            }
            if state==0{
                result = "🔥"+result!
            }else{
                result = "❄️"+result!
            }
            }else{
                result = "🔥等待干燥开始..."
            }
        }
        return result
    }
    
    /**
     * 当用户滚动或拖动时触发,继承于UIScrollViewDelegate协议
     * 画时间座标轴相关内容和温度线
     * @param
     *    scrollView - UIPickerView 类型，指定滚动框
     * @return
     *     Void
     */
    func scrollViewDidScroll(_ scrollView:UIScrollView){
        drawTimeAndTemperature()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView:UIScrollView){
        /* 当滚动结束时触发 */
        //scrollView.alpha = 1
        //scrollPos += scrollStartPoint.x-scrollView.accessibilityActivationPoint.x
        //drawGrad(dx:Int(scrollPos),rect: viewBounds)
    }
    
    func scrollViewDidEndDragging(_ scrollView:UIScrollView,willDecelerate:Bool){
        /*  */
        //scrollView.alpha = 1
        //scrollPos += scrollStartPoint.x-scrollView.accessibilityActivationPoint.x
        //drawGrad(dx:Int(scrollPos),rect: viewBounds)
    }
    
    /**
     * 画时间座标轴相关内容和温度线
     * @param
     *    none
     * @return
     *     Void
     */
    func drawTimeAndTemperature()->Void{
        Draw.grad(dx:Int(scrollView.contentOffset.x),rect: viewBounds)
        if ViewController.temperatureDatas.count>0{
            Draw.temperature(recs: ViewController.temperatureDatas)
        }
    }
    
    /**
     * 触摸选择框"确定"按钮事件处理程序
     * @param
     *    sender - UIButton 类型，指定近按键
     * @return
     *     Void
     */
    func getPickerViewValue(sender:UIButton){
        valuePicker = pickerView.selectedRow(inComponent: 0)
        if btnPicker.tag == 100{ // 选择缩放
            btnPicker.setTitle(scales[valuePicker], for:.normal)
            
            // 调整滚动棒当前位置
            scrollView.contentOffset.x *= CGFloat(Draw.scales[Draw.scale])/CGFloat(Draw.scales[valuePicker])
            
            Draw.scale = valuePicker // 设置单位索引
            drawTimeAndTemperature()
        }
        else if btnPicker.tag==101 {// 选择干燥记录
            var title:String?
            
            //定时器取消，会销毁
            ViewController.timer?.cancel()
            ViewController.timer1?.cancel()
            
            ViewController.temperatureDatas.removeAllObjects()
            DataController(name: "DryData").removeAll()
            
            if valuePicker<dryingRecord.count{
                let state=dryingRecord[valuePicker]["state"] as! Int
                title = dryingRecord[valuePicker]["starttime"] as! String?
                let id = Int(dryingRecord[valuePicker]["id"] as! String)
                let no = Int(dryingRecord[valuePicker]["lineno"] as! Int)
                if state==0{// 正在干燥的记录
                    title = "🔥"+title!
                    inTimeRequest(mainid: id!)
                }else{// 已干燥的记录
                    title = "❄️"+title!
                    findNewData(mainid: id!)
                }
                self.getDryLine(lineno:no)
            }else{
                title = "🔥等待干燥开始..."
                inTimeRequestMain()
             }
            btnPicker.setTitle(title, for:.normal)
        }
        vmPicker.removeFromSuperview()
        setButtonsEnabled(enabled:true)
    }
    
    /**
     * 实时等待干燥开始
     * @param
     *    none
     * @return
     *     Void
     */
    func checkDryStart()->Void{
        // 远程获得干燥记录数据
        let drymain = DataController(name: "DryMain")
        let condition = [["field":"state","value":0,"operator":"eq"]]
        let attrs = drymain.attributes()
        let param = ["filter": attrs,"cond":condition] as [String : Any]
        Network.request(method: "GET", url: drymain.url(), params: param, success: {(result) in
            if (result?.count)!>0{
                //定时器取消，会销毁
                ViewController.timer?.cancel()
            
                var item = result?[0]
                var title = item?["starttime"] as! String?
                var mainid = Int((item?["id"] as! String?)!)
                var no = (item?["lineno"] as! Int?)!
                let btn = self.view.viewWithTag(101) as! UIButton
                btn.setTitle("🔥"+title!, for: .normal)
                self.dryingRecord.append(item!)
                self.inTimeRequest(mainid: mainid!)
                self.getDryLine(lineno:no)
            }
        }, failure: {(error) in
            print(error)
        })
    }
    
    /**
     * 从远端服务器，取设定干燥曲线
     * @param
     *    lineno - Int  类型，指定干燥曲线的曲线号
     * @return
     *     Void
     */
    func getDryLine(lineno:Int)->Void{
        // 远程获得干燥记录数据
        let drymain = DataController(name: "DryLine")
        let condition = [["field":"lineno","value":lineno,"operator":"eq"]]
        let attrs = drymain.attributes()
        let param = ["filter": attrs,"cond":condition] as [String : Any]
        Network.request(method: "GET", url: drymain.url(), params: param, success: {(result) in
            if (result?.count)!>0{
                ViewController.lineTime.removeAll()
                ViewController.lineEndTemperature.removeAll()
                for item in result!{
                    ViewController.lineTime.append(item["time"] as! Int)
                    ViewController.lineEndTemperature.append(item["temperature"] as! Int)
                }
            }
        }, failure: {(error) in
            print(error)
        })
    }

    /**
     * 设置定时器，向服务器请求 DryMain 实时数据（干燥未开始情况下）
     * @param
     *    none
     * @return
     *     Void
     */
    func inTimeRequestMain()->Void{
        ViewController.isWiatDry = true
        
        // 设置定时器，每10秒向服务器发请求一次
        ViewController.timer = DispatchSource.makeTimerSource(flags: [], queue:DispatchQueue.global())
        ViewController.timer?.scheduleRepeating(deadline: .now(), interval: .seconds(10) ,leeway:.milliseconds(40))
        ViewController.timer?.setEventHandler {
            //该处设定要执行的事件，比如说要定时器控制的界面的刷新等等，记住，要用主线程刷新，不然会有延迟
            self.checkDryStart()
            timerCount += 1
        }
        // 启动时间源
        ViewController.timer?.resume()
    }
    
    /**
     * 设置定时器，向服务器请求 DryData 实时数据（干燥已开始）
     * @param
     *    mainid - Int 类型，指定表 DryData 中 mainid 字段值，返回记录的 mainid 字段必须等于该值
     * @return
     *     Void
     */
    func inTimeRequest(mainid:Int)->Void{
        ViewController.isWiatDry = false
        
        // 设置定时器，每10秒向服务器发请求一次
        ViewController.timer1 = DispatchSource.makeTimerSource(flags: [], queue:DispatchQueue.global())
        ViewController.timer1?.scheduleRepeating(deadline: .now(), interval: .seconds(10) ,leeway:.milliseconds(40))
        ViewController.timer1?.setEventHandler {
            //该处设定要执行的事件，比如说要定时器控制的界面的刷新等等，记住，要用主线程刷新，不然会有延迟
            self.findNewData(mainid:mainid)
            timerCount += 1
        }
        // 启动时间源
        ViewController.timer1?.resume()
    }
    
    /**
     * 取实时干燥数据
     * @param
     *    mainid - Int 类型，指定表 DryData 中 mainid 字段值，返回记录的 mainid 字段必须等于该值
     * @return
     *     Void
     */
    func findNewData(mainid:Int)->Void{
        // 远程获得干燥记录数据
        let drymain = DataController(name: "DryData")
        var lastId = 0
        if let last = ViewController.temperatureDatas.lastObject as! Dictionary<String, Any>?{
            if let id = Int(last["id"] as! String){
                lastId = id
            }
        }
        let condition = [
            ["field":"mainid","value":mainid,"operator":"eq"]
            ,["field":"id","value":lastId,"operator":"gt"]
        ]
        let param = ["filter": drymain.attributes(),"cond":condition] as [String : Any]
        Network.request(method: "GET", url: drymain.url(), params: param, success: {(result) in
            if (result?.count)!>0{
                let recs = drymain.recordToArray(records: result,eachRecord: {(item) in
                    // 保存干燥曲线每个段的开始时间
                    let mode = (item as AnyObject).value(forKey: "mode") as! Int
                    if ViewController.currentLineNo != mode{
                        let time = (item as AnyObject).value(forKey: "time")!
                        ViewController.lineStartTime.append(time as! Int)
                        ViewController.currentLineNo = mode
                    }
                    })

                drymain.appendRecord(data: result)
                ViewController.temperatureDatas.addObjects(from: recs)
                
                Draw.temperature(recs: ViewController.temperatureDatas)
                self.showDryData(rec: recs.last as! Dictionary<String, Any>)
            }
        }, failure: {(error) in
            print(error)
        })
    }
    
    /**
     * 设置干燥记录和时间单位按键使能状态
     * @param
     *    enabled - Bool 类型，指定要设置的按键状态
     * @return
     *     Void
     */
    func setButtonsEnabled(enabled:Bool)->Void{
        for i in 100...101{
            let btn = self.view.viewWithTag(i) as! UIButton
            btn.isEnabled = enabled
        }
    }
    
    /**
     * 触摸选择框"取消"按钮事件处理程序
     * @param
     *    sender - UIButton 类型，指定按键
     * @return
     *     Void
     */
    func cancelPickerViewValue(sender:UIButton){
        vmPicker.removeFromSuperview()
        setButtonsEnabled(enabled:true)
    }

    /**
     * 显示干燥数据
     * @param
     *    rec - Dictionary<String, Any> 类型，指定要显示的记录
     * @return
     *     Void
     */
    func showDryData(rec:Dictionary<String, Any>)->Void{
        let time = rec["time"] as! Int
        let tm = rec["temperature"] as! Int
        let tn = rec["settingtemperature"] as! Int
        let tDiff = tm-tn
        let mode = rec["mode"] as! Int
        let line_time = time - ViewController.lineStartTime[mode]
        var diff:String
        var audioName:String?
        var soundID:SystemSoundID = 0
        ViewController.lbStatus?.backgroundColor = UIColor.green
        
        // 设置警告声音和颜色
        if tDiff > 48{
            diff = "太高"
            ViewController.lbStatus?.backgroundColor = UIColor.red
            audioName = "alarm.caf"
            soundID = 1005
        }else if tDiff < -48{
            ViewController.lbStatus?.backgroundColor = UIColor.red
            diff = "太低"
            audioName = "alarm.caf"
            soundID = 1005
        }else if tDiff > 32{
            diff = "偏高"
            ViewController.lbStatus?.backgroundColor = UIColor.yellow
            audioName = "Bloom.caf"
            soundID = 1106
        }else if tDiff < -32{
            diff = "偏低"
            ViewController.lbStatus?.backgroundColor = UIColor.yellow
            audioName = "Bloom.caf"
            soundID = 1106
        }else{
            diff = "正常"
            audioName = nil
            soundID = 0
        }
        
        // 起动多线程
        DispatchQueue.global().async {
            if ViewController.isPlaying==false{
                ViewController.isPlaying = true
                
                //添加音频结束时的回调
                AudioServicesAddSystemSoundCompletion (
                    soundID,
                    nil,
                    nil,
                    {
                        (soundID: UInt32,inClientData: Optional<UnsafeMutableRawPointer>) in
                        let delegate = unsafeBitCast(inClientData, to: AudioServicesPlaySystemSoundDelegate.self)
                        delegate.audioServicesPlaySystemSoundCompleted(soundID: soundID)
                    },
                    UnsafeMutableRawPointer(mutating:  Unmanaged.passRetained(self).toOpaque())
                )
                //播放声音
                AudioServicesPlaySystemSound(soundID)
            }
        }
        
        // 最小二乘法,计算给定点的实际升温速度
        let pos = ViewController.temperatureDatas.index(of: rec) as Int
        let least = LeastSquare(datas: ViewController.temperatureDatas,current:pos)
        
        var velocity:Float = 0.0
        var lineStatus = String(ViewController.lineEndTemperature[mode])+"℃"
        if mode%2==0{
            velocity = Float(ViewController.lineTime[mode])
            if mode < ViewController.lineTime.count - 1{
                lineStatus = lineStatus+" 升温"
            }else{
                lineStatus = lineStatus+" 降温"
            }
        }else{
            lineStatus = lineStatus+" 保温"

        }
        ViewController.lbSettingTemperature?.text = String(format: "%.1f", Float(tn)/16.0)
        ViewController.lbTemperature?.text = String(format: "%.1f", Float(tm)/16.0)
        ViewController.lbSettingVelocity?.text = String(format: "%.1f", velocity)
        ViewController.lbRealVelocity?.text = String(format: "%.1f", least.getVelocity())
        ViewController.lbLineTime?.text = String(format: "%02d:%02d:%1d0", line_time/360,(line_time/6)%60,line_time%6)
        ViewController.lbRunTime?.text = String(format: "%02d:%02d:%1d0", time/360,(time/6)%60,time%6)
        ViewController.lbLineStatus?.text = lineStatus
        ViewController.lbStatus?.text = String(format: "温差 %.1f℃, \(diff)", Float(tDiff)/16.0)
    }
    
    /**
     * 声音播放完毕回调处理函数
     * @param
     *    soundID - SystemSoundID 类型，指定播放的声音
     * @return
     *     Void
     */
    func audioServicesPlaySystemSoundCompleted(soundID: SystemSoundID) {
        ViewController.isPlaying = false
        ViewController.playingSoundID = soundID
        AudioServicesRemoveSystemSoundCompletion(soundID)
        AudioServicesDisposeSystemSoundID(soundID)
    }
    
}

/**
 * 声音播放完毕回调处理代理协议
 */
@objc protocol AudioServicesPlaySystemSoundDelegate {
    func audioServicesPlaySystemSoundCompleted(soundID: SystemSoundID)
}

