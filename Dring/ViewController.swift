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
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    //长按手势
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
        Draw.vCoord(rect: viewBounds)
        Draw.grad(dx:0,rect: viewBounds)
        Draw.frame(x:6,y:viewBounds.midY+viewBounds.height-253,width:160,height:55,stringWidth:65)
        Draw.frame(x:186,y:viewBounds.midY+viewBounds.height-253,width:200,height:55,stringWidth:35)
        Draw.frame(x:407,y:viewBounds.midY+viewBounds.height-253,width:126,height:55,stringWidth:35)
        
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
    
    // 创建一个选择框
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
    
    //
    func createPickByBtn(btn:UIButton,title:String)->Void{
        btnPicker = btn
        if btn.isEnabled{
            setButtonsEnabled(enabled:false)
            createPickerview(title:title)
        }
    }
    
    // 缩放按键 touch up inside 事件处理程序
    @IBAction func scale(_ sender: UIButton) {
        createPickByBtn(btn:sender,title:"设置时间单位")
    }
    
    // 干燥曲线按键 touch up inside 事件处理程序
    @IBAction func dryingDate(_ sender: UIButton) {
        createPickByBtn(btn:sender,title:"选择干燥记录")
    }
    
    //设置选择框的列数为1列,继承于UIPickerViewDataSource协议
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //设置选择框的行数，继承于UIPickerViewDataSource协议
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
    
    //设置选择框各选项的内容，继承于UIPickerViewDelegate协议
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
    
    func scrollViewDidScroll(_ scrollView:UIScrollView){
        /* 当用户滚动或拖动时触发 */
        drawTimeAndTemperature()
       //scrgollStartPoint = UIEvent.tou mouseLocation()
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
    
    // 重画时间线、时间单位值和温度曲线
    func drawTimeAndTemperature()->Void{
        Draw.grad(dx:Int(scrollView.contentOffset.x),rect: viewBounds)
        if ViewController.temperatureDatas.count>0{
            Draw.temperature(recs: ViewController.temperatureDatas)
        }
    }
    
    // 触摸选择框"确定"按钮事件处理程序
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
            
            ViewController.temperatureDatas.removeAllObjects()
            DataController(name: "DryData").removeAll()
            
            if valuePicker<dryingRecord.count{
                //定时器取消，会销毁
                ViewController.timer?.cancel()
                
                let state=dryingRecord[valuePicker]["state"] as! Int
                title = dryingRecord[valuePicker]["starttime"] as! String?
                if state==0{// 正在干燥的记录
                    title = "🔥"+title!
                }else{// 已干燥的记录
                    title = "❄️"+title!
                }
                
                // 显示等待信息
                //ViewController.lbLoading = UILabel(frame: CGRect(x:300,y:200,width:200,height:50))
                //ViewController.lbLoading.text = "Loading..."
                //self.view.addSubview(ViewController.lbLoading)
                
                // 向服务器请求数据
                let id = dryingRecord[valuePicker]["id"] as! String
                findNewData(mainid: Int(id)!)
                //DataController(name: "DryData").fetchDryData(mainid: dryingRecord[valuePicker]["id"] as! String,params: nil)
            }else{
                title = "🔥等待干燥开始..."
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
            btnPicker.setTitle(title, for:.normal)
        }
        vmPicker.removeFromSuperview()
        setButtonsEnabled(enabled:true)
    }
    
    // 实时等待干燥开始
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
                let btn = self.view.viewWithTag(101) as! UIButton
                btn.setTitle("🔥"+title!, for: .normal)
                self.dryingRecord.append(item!)
                self.inTimeRequest(mainid: mainid!)
            }
        }, failure: {(error) in
            print(error)
        })
    }
    
    // 设置定时器，向服务器请求 DryData 实时数据
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
    
    // 取实时干燥数据
    func findNewData(mainid:Int)->Void{
        // 远程获得干燥记录数据
        let drymain = DataController(name: "DryData")
        var lastId = 0
        if let last = ViewController.temperatureDatas.lastObject as! Dictionary<String, Any>?{
            lastId = last["id"] as! Int
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
                /*
                //通知名称常量
                let refresh = NSNotification.Name(rawValue:"refresh")
                let noti = NSNotification(name: refresh, object: self, userInfo: ["value":"DryData"])
                let notiCenter = NotificationCenter.default
                // 先注册通知监听者
                notiCenter.addObserver(self, selector: #selector(self.testNoti(noti:)), name: refresh, object: self)
                
                //延时2s
                sleep(2)
                // 发布通知
                notiCenter.post(noti as Notification)//之前直接使用Notification就没有这样as来转换了
 */
            }
        }, failure: {(error) in
            print(error)
        })
    }
    
    func setButtonsEnabled(enabled:Bool)->Void{
        for i in 100...101{
            let btn = self.view.viewWithTag(i) as! UIButton
            btn.isEnabled = enabled
        }
    }
    
    //触摸选择框"取消"按钮事件处理程序
    func cancelPickerViewValue(sender:UIButton){
        vmPicker.removeFromSuperview()
        setButtonsEnabled(enabled:true)
    }

    // 显示干燥数据
    func showDryData(rec:Dictionary<String, Any>)->Void{
        let time = rec["time"] as! Int
        let tm = rec["temperature"] as! Int
        let tn = rec["settingtemperature"] as! Int
        let tDiff = tm-tn
        let mode = rec["mode"] as! Int
        let lineTime = time - ViewController.lineStartTime[mode]
        var diff:String
        var audioName:String?
        ViewController.lbStatus?.backgroundColor = UIColor.green
        
        // 设置警告声音和颜色
        if tDiff > 48{
            diff = "太高"
            ViewController.lbStatus?.backgroundColor = UIColor.red
            audioName = "alarm.caf"
        }else if tDiff < -48{
            ViewController.lbStatus?.backgroundColor = UIColor.red
            diff = "太低"
            audioName = "alarm.caf"
        }else if tDiff > 32{
            diff = "偏高"
            ViewController.lbStatus?.backgroundColor = UIColor.yellow
            audioName = "Bloom.caf"
        }else if tDiff < -32{
            diff = "偏低"
            ViewController.lbStatus?.backgroundColor = UIColor.yellow
            audioName = "Bloom.caf"
        }else{
            diff = "正常"
            audioName = nil
        }
        
        // 起动多线程
        DispatchQueue.global().async {
            // 播放音频
            if let name = audioName {
                //建立的SystemSoundID对象
                var soundID:SystemSoundID = 0
                //地址转换
                if let fileUrl = Bundle.main.url(forResource:name,withExtension:nil){
                    //赋值
                    AudioServicesCreateSystemSoundID(fileUrl as CFURL, &soundID)
                    //提醒（同上面唯一的一个区别）
                    AudioServicesPlayAlertSound(soundID)
                }
                DispatchQueue.main.async {  //通知ui刷新
                }
            }
        }
        
        // 最小二乘法
        let least = LeastSquare(datas: ViewController.temperatureDatas)
        
        ViewController.lbSettingTemperature?.text = String(format: "%.1f", Float(tn)/16.0)
        ViewController.lbTemperature?.text = String(format: "%.1f", Float(tm)/16.0)
        ViewController.lbRealVelocity?.text = String(format: "%.2f", least.getVelocity())
        ViewController.lbLineTime?.text = String(format: "%02d:%02d:%1d0", lineTime/360,(lineTime/6)%60,lineTime%6)
        ViewController.lbRunTime?.text = String(format: "%02d:%02d:%1d0", time/360,(time/6)%60,time%6)
        ViewController.lbStatus?.text = String(format: "温差 %.1f℃, \(diff)", Float(tDiff)/16.0)
    }
    
    // selector是这样的
    func testNoti(noti: Notification) {
        ViewController.lbLoading.removeFromSuperview()
        var t = noti.userInfo!
        let t1 = t.popFirst()
        var currentLineno = 0
        ViewController.temperatureDatas = DataController(name:t1?.value as! String).findAll(eachRecord: {(item) in
            // 保存干燥曲线每个段的开始时间
            let mode = (item as AnyObject).value(forKey: "mode") as! Int
            if currentLineno != mode{
                let time = (item as AnyObject).value(forKey: "time")!
                ViewController.lineStartTime.append(time as! Int)
                currentLineno = mode
            }
            })
        Draw.temperature(recs: ViewController.temperatureDatas)
        showDryData(rec: ViewController.temperatureDatas.lastObject as! Dictionary<String, Any>)
    }
    
}

