//
//  ViewController.swift
//  Dring
//
//  Created by 刘兴明 on 16/01/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import UIKit
import CoreData

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,UIScrollViewDelegate{
    var vmPicker:UIView!
    
    var pickerView: UIPickerView!
    var scrollView: UIScrollView!
    var btnPicker: UIButton!
    var scales = ["默认","4 小时","8 小时","12 小时","24 小时","48 小时","96 小时"]
    var dryingRecord:[Dictionary<String, Any>] = []
    var valuePicker:Int = 0
    var scrollPos:CGFloat = 0.0
    var scrollStartPoint:CGPoint!
    var viewBounds:CGRect!
    var moveTextLayers:[CATextLayer] = []
    var moveLayers:[(CAShapeLayer ,UIBezierPath,CGFloat)] = [(CAShapeLayer(),UIBezierPath(),0.5),(CAShapeLayer(),UIBezierPath(),1.0)]
    
    var drawGrad:Bool = true
    
    /*
     * 在给定区域绘制字符串
     */
    func drawText(x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,s:String)->Void{
        let tLayer=CATextLayer()
        tLayer.frame=CGRect(x:x, y:y, width:width, height:height)
        tLayer.string = s
        let fontName:CFString = "Noteworthy-Light" as CFString
        tLayer.font = CTFontCreateWithName(fontName, 9.0, nil)
        tLayer.fontSize = 9.0
        tLayer.foregroundColor = UIColor.black.cgColor
        tLayer.contentsScale = UIScreen.main.scale
        tLayer.alignmentMode = kCAAlignmentRight
        view.layer.addSublayer(tLayer)
    }
    
    /*
     * 在给定区域绘制字符串
     */
    func drawMoveText(tLayer:CATextLayer,x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,s:String)->Void{
        tLayer.frame=CGRect(x:x, y:y, width:width, height:height)
        tLayer.string = s
        view.layer.addSublayer(tLayer)
    }
    
    /*
     * 画 frame 控件外框
     */
    func drawFrame(x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,stringWidth:CGFloat)->Void{
        let layer=CAShapeLayer()
        layer.frame=CGRect(x:x, y:y, width:width, height:height)
        
        //利用UIBezierPath绘制简单的矩形
        let path=UIBezierPath()
        path.move(to: CGPoint(x:0,y:0))
        path.addLine(to: CGPoint(x:5,y:0))
        path.move(to: CGPoint(x:5+stringWidth,y:0))
        path.addLine(to: CGPoint(x:layer.frame.width,y:0))
        path.addLine(to: CGPoint(x:layer.frame.width,y:layer.frame.height))
        path.addLine(to: CGPoint(x:0,y:layer.frame.height))
        path.addLine(to: CGPoint(x:0,y:0))
        layer.path=path.cgPath
        //填充颜色
        layer.fillColor=UIColor.clear.cgColor
        //边框颜色
        layer.strokeColor=UIColor.black.cgColor
        view.layer.addSublayer(layer)
    }
    
    // 画水平线及座标
    func drawVCoord(rect:CGRect)->Void{
        let layer:[(CAShapeLayer,UIBezierPath,CGFloat)]=[(CAShapeLayer(),UIBezierPath(),0.5),(CAShapeLayer(),UIBezierPath(),0.8)]
        for item in layer{
            item.0.frame=CGRect(x:0, y:25, width:rect.width, height:rect.height-25-50)
        }
        //layer.backgroundColor=UIColor.black.cgColor
        //view.layer.addSublayer(layer)
        
        //利用UIBezierPath绘制简单的矩形
        layer[0].1.move(to: CGPoint(x:0,y:0))
        layer[0].1.addLine(to: CGPoint(x:layer[0].0.frame.width,y:0))
        layer[0].1.addLine(to: CGPoint(x:layer[0].0.frame.width,y:layer[0].0.frame.height))
        layer[0].1.addLine(to: CGPoint(x:0,y:layer[0].0.frame.height))
        layer[0].1.addLine(to: CGPoint(x:0,y:0))
        
        // 绘图区域高度
        let coordHeight = layer[0].0.frame.height - 30
        
        // 座标线间隔
        let coordSpace:Int = Int(coordHeight / 22.0)
        var n = -50
        let maxY = layer[0].0.frame.minX + coordHeight-1
        let frameLeft:CGFloat = 30.0
        let x = frameLeft
        
        // 座标刻线长度
        var x0:CGFloat
        
        // 画垂直座标轴
        for i in 0...22{
            let y0 = maxY - CGFloat(i * coordSpace)
            if (n % 50 == 0){
                x0 = 8
                
                if (n >= -50){
                    layer[0].1.move(to: CGPoint(x:x, y:y0))
                    layer[0].1.addLine(to: CGPoint(x:rect.width,y:y0))
                }
                
                // 绘制垂直座标轴刻度值
                drawText(x: x-frameLeft, y: y0+17, width: frameLeft-10, height: 12, s: "\(n)")
            }else{
                x0 = 5
                layer[1].1.move(to: CGPoint(x:x, y:y0))
                layer[1].1.addLine(to: CGPoint(x:rect.width,y:y0))
            }
            
            // 画垂直座标轴刻线
            layer[0].1.move(to: CGPoint(x:x-x0, y:y0))
            layer[0].1.addLine(to: CGPoint(x:x,y:y0))
            
            n += 10
        }
        layer[0].1.move(to:CGPoint(x:frameLeft,y:0))
        layer[0].1.addLine(to:CGPoint(x:frameLeft,y:maxY))
        //path.move(to:CGPoint(x:frameLeft,y:layer.frame.height))
        //path.addLine(to:CGPoint(x:frameLeft,y:layer.frame.height))
        
        // 绘制垂直座标轴单位
        drawText(x: x-frameLeft, y: layer[0].0.frame.minY, width: frameLeft-10, height: 12, s: "℃")
        for item in layer{
            item.0.path=item.1.cgPath
            //填充颜色
            item.0.fillColor=UIColor.clear.cgColor
            //边框颜色
            let color:CGFloat = item.2
            item.0.strokeColor=UIColor.init(red: color, green: color, blue: color, alpha: 1.0).cgColor
            view.layer.addSublayer(item.0)
        }
    }
    
    /*
     * 绘制网格线
     * @param dx - int ,指定滚动棒位置
     * @return void
     */
    func drawGrad(dx:Int,rect:CGRect)->Void {
        if drawGrad {
            for moveLayer in moveLayers{
                let theLayer = moveLayer.0
                moveLayer.1.removeAllPoints()
                theLayer.frame=CGRect(x:0, y:25, width:rect.width, height:rect.height-20-50)
                if (view.layer.sublayers?.contains(theLayer))!{
                    theLayer.removeFromSuperlayer()
                }
                
            }
            for moveLayer in moveTextLayers{
                moveLayer.removeFromSuperlayer()
            }
            
            // 绘图区域高度
            let coordHeight = moveLayers[0].0.frame.height - 30
            
            // 座标线间隔
            //let coordSpace:Int = Int(coordHeight / 22.0)
            //var n = -50
            let maxY = moveLayers[0].0.frame.minX + coordHeight-1
            let frameLeft:CGFloat = 30.0
            let x = frameLeft
            let times = Int(moveLayers[0].0.frame.width/60)
            let startValue = dx%60
            
            // 绘制网格垂直线
            for i in 0...times {
                if moveTextLayers.count < i+1 {
                    // 水平刻度值 CATextLayer
                    let tLayer = CATextLayer()
                    let fontName:CFString = "Noteworthy-Light" as CFString
                    tLayer.font = CTFontCreateWithName(fontName, 9.0, nil)
                    tLayer.fontSize = 9.0
                    tLayer.foregroundColor = UIColor.black.cgColor
                    tLayer.contentsScale = UIScreen.main.scale
                    tLayer.alignmentMode = kCAAlignmentCenter
                    
                    moveTextLayers.append(tLayer)
                }
                
                let xe = CGFloat(i*60-startValue)
                if xe > 0 {
                    moveLayers[0].1.move(to: CGPoint(x:x+xe, y:0))
                    moveLayers[0].1.addLine(to: CGPoint(x:x+xe,y:maxY))
                    
                    let time = dx/60+i
                    let sHour = String(format:"%2d",time/6)
                    let sMinute = String(format:"%02d",(time%6)*10)
                    let s = "\(sHour):\(sMinute)"
                    
                    // 绘制垂直座标轴刻度值
                    drawMoveText(tLayer:moveTextLayers[i], x: x+xe-20, y: maxY+25, width: 40, height: 12, s: "\(s)")
                }
            }
            
            for moveLayer in moveLayers{
                let layer1:CAShapeLayer = moveLayer.0
                
                layer1.path=moveLayer.1.cgPath
                //填充颜色
                layer1.fillColor=UIColor.white.cgColor
                //边框颜色
                let color:CGFloat = moveLayer.2
                let acolor = UIColor.init(red: color, green: color, blue: color, alpha: 1.0)
                layer1.strokeColor=acolor.cgColor
                
                view.layer.addSublayer(layer1)
            }
        }
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //获取屏幕大小（不包括状态栏高度）
        viewBounds = CGRect(x:0,y:20,
                            width:UIScreen.main.bounds.width,
                            height:UIScreen.main.bounds.height-20)
        drawVCoord(rect: viewBounds)
        drawGrad(dx:0,rect: viewBounds)
        drawFrame(x:6,y:viewBounds.midY+viewBounds.height-253,width:102,height:55,stringWidth:65)
        drawFrame(x:128,y:viewBounds.midY+viewBounds.height-253,width:112,height:55,stringWidth:35)
        drawFrame(x:260,y:viewBounds.midY+viewBounds.height-253,width:123,height:55,stringWidth:35)
        
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
            }
        }, failure: {(error) in
            print(error)
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
    
    // 缩放按键 touch up inside 事件处理程序
    @IBAction func scale(_ sender: UIButton) {
        btnPicker = sender
        createPickerview(title:"设置缩放参数")
    }
    
    // 干燥曲线按键 touch up inside 事件处理程序
    @IBAction func dryingDate(_ sender: UIButton) {
        btnPicker = sender
        createPickerview(title:"选择干燥记录")
    }
    
    //设置选择框的列数为1列,继承于UIPickerViewDataSource协议
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //设置选择框的行数，继承于UIPickerViewDataSource协议
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        if btnPicker.tag == 100{
            return scales.count
        }
        else if btnPicker.tag==101 {
            return dryingRecord.count
        }
        return 0
    }
    
    //设置选择框各选项的内容，继承于UIPickerViewDelegate协议
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if btnPicker.tag == 100{
            return scales[row]
        }
        else if btnPicker.tag==101 {
            for item in dryingRecord[row]{
                if item.key=="starttime"{
                    return item.value  as? String
                }
            }
        }
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView:UIScrollView){
        /* 当用户滚动或拖动时触发 */
        drawGrad(dx:Int(scrollView.contentOffset.x),rect: viewBounds)
        
        //scrollStartPoint = UIEvent.tou mouseLocation()
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
    
    //触摸按钮时，获得被选中的索引
    func getPickerViewValue(sender:UIButton){
        valuePicker = pickerView.selectedRow(inComponent: 0)
        if btnPicker.tag == 100{
            btnPicker.setTitle(scales[valuePicker], for:.normal)
        }
        else if btnPicker.tag==101 {
            btnPicker.setTitle(dryingRecord[valuePicker]["starttime"] as! String?, for:.normal)
            DataController(name: "DryData").fetchDryData(mainid: dryingRecord[valuePicker]["id"] as! String,params: nil)
        }
        //cancelPickerViewValue(sender: <#T##UIButton#>)
        //pickerView.removeFromSuperview()
        //sender.removeFromSuperview()
        vmPicker.removeFromSuperview()
    }
    
    //触摸按钮时，获得被选中的索引
    func cancelPickerViewValue(sender:UIButton){
        //pickerView.removeFromSuperview()
        //sender.removeFromSuperview()
        vmPicker.removeFromSuperview()
    }
    
}

