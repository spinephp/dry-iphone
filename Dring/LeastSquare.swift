//
//  LeastSquare.swift
//  Dring
//
//  Created by 刘兴明 on 28/03/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import Foundation

class LeastSquare{
    var a:Double = 0.0
    var b:Double = 0.0
    init(datas:NSMutableArray)
    {
        var t1:Double=0, t2:Double=0,t3:Double=0, t4:Double=0
        var i = 0
        if datas.count>50{
            i =  datas.count-50
        }
        for j in i..<datas.count{
            let r = datas[j] as! Dictionary<String, Any>
            let time = r["time"] as! UInt64
            let hour = Double(time)/360.0
            let t:Double = Double(r["temperature"] as! Int)/16.0
            t1 += hour*hour
            t2 += hour
            t3 += hour*t
            t4 += t
        }
        let count:Double = Double(datas.count)
        let m = Double(t1)*count - Double(t2*t2)
        a = (t3*count - Double(t2)*t4) / m
        //b = (t4 - a*t2) / x.size()
        b = (Double(t1)*t4 - Double(t2)*t3) / m
    }
    
    func getY(x:Double)->Double
    {
        return a*x + b
    }
    
    func getVelocity()->Double{
        return a
    }
}
