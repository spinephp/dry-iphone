//
//  ViewController.swift
//  Dring
//
//  Created by 刘兴明 on 16/01/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    func drawCoord()->Void{
        let layer=CAShapeLayer()
        layer.frame=CGRect(x:0, y:50, width:150, height:100)
        //layer.backgroundColor=UIColor.black.cgColor
        //view.layer.addSublayer(layer)
        
        //利用UIBezierPath绘制简单的矩形
        let path=UIBezierPath()
        path.move(to:CGPoint(x:40,y:0))
        path.addLine(to:CGPoint(x:40,y:300))
        //let layer=CAShapeLayer()
        layer.path=path.cgPath
        //填充颜色
        layer.fillColor=UIColor.black.cgColor
        //边框颜色
        layer.strokeColor=UIColor.black.cgColor
        view.layer.addSublayer(layer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        drawCoord()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

