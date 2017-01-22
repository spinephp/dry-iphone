//
//  ViewController.swift
//  Dring
//
//  Created by 刘兴明 on 16/01/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    func drawVCoord(rect:CGRect)->Void{
        let layer=CAShapeLayer()
        layer.frame=CGRect(x:0, y:50, width:rect.width, height:rect.height-50-50)
        //layer.backgroundColor=UIColor.black.cgColor
        //view.layer.addSublayer(layer)
        
        //利用UIBezierPath绘制简单的矩形
        let path=UIBezierPath()
        path.move(to: CGPoint(x:0,y:0))
        path.addLine(to: CGPoint(x:layer.frame.width,y:0))
        path.addLine(to: CGPoint(x:layer.frame.width,y:layer.frame.height))
        path.addLine(to: CGPoint(x:0,y:layer.frame.height))
        path.addLine(to: CGPoint(x:0,y:0))
        
        path.move(to:CGPoint(x:40,y:0))
        path.addLine(to:CGPoint(x:40,y:layer.frame.height))
        path.move(to:CGPoint(x:30,y:layer.frame.height))
        path.addLine(to:CGPoint(x:40,y:layer.frame.height))
        
        //let layer=CAShapeLayer()
        layer.path=path.cgPath
        //填充颜色
        layer.fillColor=UIColor.clear.cgColor
        //边框颜色
        layer.strokeColor=UIColor.black.cgColor
        view.layer.addSublayer(layer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //获取屏幕大小（不包括状态栏高度）
        let viewBounds = CGRect(x:0,y:20,
                                       width:UIScreen.main.bounds.width,
                                       height:UIScreen.main.bounds.height-20)
        drawVCoord(rect: viewBounds)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

