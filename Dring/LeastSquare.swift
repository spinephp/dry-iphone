//
//  LeastSquare.swift
//  Dring
//
//  Created by 刘兴明 on 28/03/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import Foundation

/*
 * 最小二乘法计算升温速度
 */
class LeastSquare{
    var a:Double = 0.0
    var b:Double = 0.0

    /**
     * 类初始化函数
     * @param
     *     datas - NSMutableArray 类型，指定要处理的温度数据数组
     *     current - Int? 类型，指定当前温度值的索引
     */
    init(datas:NSMutableArray,current:Int?)
    {
        var t1:Double=0, t2:Double=0,t3:Double=0, t4:Double=0
        var i = 0
        var len:Int = datas.count-1
        if (current != nil){
            len = current!
        }
        if len>50{
            i =  len-50
        }
        for j in i..<len{
            let r = datas[j] as! Dictionary<String, Any>
            let time = r["time"] as! UInt64
            let hour = Double(time)/360.0
            let t:Double = Double(r["temperature"] as! Int)/16.0
            t1 += hour*hour
            t2 += hour
            t3 += hour*t
            t4 += t
        }
        let count:Double = Double(len-i)
        let m = Double(t1)*count - Double(t2*t2)
        a = (t3*count - Double(t2)*t4) / m
        //b = (t4 - a*t2) / x.size()
        b = (Double(t1)*t4 - Double(t2)*t3) / m
    }
    
    /**
     * 取指定点的温度值
     * @param
     *     x - Double 类型，指定时间值
     *     current - Int? 类型，指定当前温度值的索引
     * @return
     *     Double, 温度值
     */
    func getY(x:Double)->Double
    {
        return a*x + b
    }
    
    /**
     * 取速度
     * @param
     *     datas - NSMutableArray 类型，指定要处理的温度数据数组
     * @return
     *     Double, 速度值
     */
    func getVelocity()->Double{
        return a
    }
}
