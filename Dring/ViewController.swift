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

var touchPoint = CGPoint(x:0,y:0)

extension UIScrollView {
    public func  touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let t:UITouch = touch as! UITouch
            //当在屏幕上连续拍动两下时，背景恢复为白色
            if(t.tapCount == 2)
            {
                let point:CGPoint = (event.allTouches?.first?.location(in: self))!
                Draw.removeSeeLine(x: point.x)
            }
                //当在屏幕上单击时，屏幕变为红色
            else if(t.tapCount == 1)
            {
                let point:CGPoint = (event.allTouches?.first?.location(in: self))!
                Draw.removeSeeLine(x: point.x)
            }
            print("event begin!")
        }
    }
    public func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.next?.touchesMoved(touches as! Set<UITouch>, with: event)
        let point:CGPoint = (event.allTouches?.first?.location(in: self))!
        Draw.removeSeeLine(x: point.x)
        Draw.drawSeeLine(x: point.x)
    }
    public func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.next?.touchesEnded(touches as! Set<UITouch>, with: event)
        
    }
}

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,UIScrollViewDelegate{
    var vmPicker:UIView!
    static var lbLoading:UILabel!
    var pickerView: UIPickerView!
    var scrollView: UIScrollView!
    var btnPicker: UIButton!
    var scales = ["默认","4 小时","8 小时","12 小时","24 小时","48 小时","96 小时"]
    var dryingRecord:[Dictionary<String, Any>] = []
    var valuePicker:Int = 0
    var scrollPos:CGFloat = 0.0
    var scrollStartPoint:CGPoint!
    var viewBounds:CGRect!
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Draw.view = self.view
        
        //获取屏幕大小（不包括状态栏高度）
        viewBounds = CGRect(x:0,y:20,
                            width:UIScreen.main.bounds.width,
                            height:UIScreen.main.bounds.height-20)
        Draw.vCoord(rect: viewBounds)
        Draw.grad(dx:0,rect: viewBounds)
        Draw.frame(x:6,y:viewBounds.midY+viewBounds.height-253,width:102,height:55,stringWidth:65)
        Draw.frame(x:128,y:viewBounds.midY+viewBounds.height-253,width:112,height:55,stringWidth:35)
        Draw.frame(x:260,y:viewBounds.midY+viewBounds.height-253,width:123,height:55,stringWidth:35)
        
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
            for item in self.view.subviews{
                if item.tag==101{
                    let btn = item as! UIButton
                    let s = ((result?.count)!>0) ? "请选择干燥记录" : "无"
                    btn.setTitle(s, for: .normal)
                }
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
        Draw.grad(dx:Int(scrollView.contentOffset.x),rect: viewBounds)
        
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
    
    //触摸按钮时，获得被选中的索引
    func getPickerViewValue(sender:UIButton){
        valuePicker = pickerView.selectedRow(inComponent: 0)
        if btnPicker.tag == 100{
            btnPicker.setTitle(scales[valuePicker], for:.normal)
        }
        else if btnPicker.tag==101 {
            btnPicker.setTitle(dryingRecord[valuePicker]["starttime"] as! String?, for:.normal)
            ViewController.lbLoading = UILabel(frame: CGRect(x:300,y:200,width:200,height:50))
            ViewController.lbLoading.text = "Loading..."
            self.view.addSubview(ViewController.lbLoading)
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
    
    // selector是这样的
    func testNoti(noti: Notification) {
        ViewController.lbLoading.removeFromSuperview()
        var t = noti.userInfo!
        let t1 = t.popFirst()
        
        let datas = DataController(name:t1?.value as! String).findAll()
        Draw.temperature(recs: datas)
        
    }
    
}

