//
//  draw.swift
//  Dring
//
//  Created by 刘兴明 on 18/03/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import UIKit
import Foundation

class Draw{
    static var temperatureData:NSMutableArray = []
    static var view:UIView? = nil
    static var drawGrad:Bool = true
    static var moveTextLayers:[CATextLayer] = []
    static var moveLayers:[(CAShapeLayer ,UIBezierPath,CGFloat)] = [(CAShapeLayer(),UIBezierPath(),0.5),(CAShapeLayer(),UIBezierPath(),1.0),(CAShapeLayer(),UIBezierPath(),0.7),(CAShapeLayer(),UIBezierPath(),1.0),(CAShapeLayer(),UIBezierPath(),1.0)]
    static var frameLeft = 30
    static var frameHeight:Int = Int(Draw.moveLayers[0].0.frame.height) - 36
    static var frameWidth:Int = Int(Draw.moveLayers[0].0.frame.width) - 30
    static var scrollX = 0
    static var scale = 0
    static var coordSpace = 0 // 温度标尺间隔
    static var xSpace = 60 //时间标尺间隔
    static var current_point = [0,0,0]
    static let scales = [1,2,3,6,12,18,24,30,36,42,48]
    var ruleTemperatureWidt:Int
    var ruleruleTimeHeight:Int
    //var scale:Int
    var offsetX:Int
    var unit:Int
    
    
    init(){
        ruleTemperatureWidt = 50
        ruleruleTimeHeight = 35
        //scale = 1
        offsetX = 0
        unit = 1
        //resize()
    }
    
    static func setDrawView(view:UIView)->Void{
        self.view = view
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapHandler(sender:)))
        tapGR.numberOfTouchesRequired = 1 //手指数
        tapGR.numberOfTapsRequired = 1 //tap次数
        tapGR.delegate = self.view as! UIGestureRecognizerDelegate?
        self.view?.addGestureRecognizer(tapGR)
     }
    
    //////手势处理函数
    @objc func tapHandler(sender:UITapGestureRecognizer) {
        if (sender.numberOfTapsRequired == 1) {
            //单指单击
            print("单指单击");
        }else if(sender.numberOfTapsRequired == 2){
            //单指双击
            print("单指双击");
        }
    }
    
    /*
     * 在给定区域绘制字符串
     */
    static func text(x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,s:String)->Void{
        let tLayer=CATextLayer()
        tLayer.frame=CGRect(x:x, y:y, width:width, height:height)
        tLayer.string = s
        let fontName:CFString = "Noteworthy-Light" as CFString
        tLayer.font = CTFontCreateWithName(fontName, 9.0, nil)
        tLayer.fontSize = 9.0
        tLayer.foregroundColor = UIColor.black.cgColor
        tLayer.contentsScale = UIScreen.main.scale
        tLayer.alignmentMode = kCAAlignmentRight
        Draw.view?.layer.addSublayer(tLayer)
    }
    
    /*
     * 在给定区域绘制字符串
     */
    static func moveText(tLayer:CATextLayer,x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,s:String)->Void{
        tLayer.frame=CGRect(x:x, y:y, width:width, height:height)
        tLayer.string = s
        Draw.view?.layer.addSublayer(tLayer)
    }
    
    /*
     * 画 frame 控件外框
     */
    static func frame(x:CGFloat,y:CGFloat,width:CGFloat,height:CGFloat,stringWidth:CGFloat)->Void{
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
        Draw.view?.layer.addSublayer(layer)
    }
    
    // 画水平线及座标(画温度标尺)
    static func vCoord(rect:CGRect)->Void{
        let layer:[(CAShapeLayer,UIBezierPath,CGFloat)]=[(CAShapeLayer(),UIBezierPath(),0.5),(CAShapeLayer(),UIBezierPath(),0.8)]
        for item in layer{
            item.0.frame=CGRect(x:0, y:25, width:rect.width, height:rect.height-25-50)
        }
        
        //利用UIBezierPath绘制简单的矩形
        layer[0].1.move(to: CGPoint(x:0,y:0))
        layer[0].1.addLine(to: CGPoint(x:layer[0].0.frame.width,y:0))
        layer[0].1.addLine(to: CGPoint(x:layer[0].0.frame.width,y:layer[0].0.frame.height))
        layer[0].1.addLine(to: CGPoint(x:0,y:layer[0].0.frame.height))
        layer[0].1.addLine(to: CGPoint(x:0,y:0))
        
        // 绘图区域高度
        let coordHeight = layer[0].0.frame.height - 30
        
        // 座标线间隔
        coordSpace = Int(coordHeight / 22.0)
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
                self.text(x: x-frameLeft, y: y0+17, width: frameLeft-10, height: 12, s: "\(n)")
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
        
        // 绘制垂直座标轴单位
        self.text(x: x-frameLeft, y: layer[0].0.frame.minY, width: frameLeft-10, height: 12, s: "℃")
        for item in layer{
            item.0.path=item.1.cgPath
            //填充颜色
            item.0.fillColor=UIColor.clear.cgColor
            //边框颜色
            let color:CGFloat = item.2
            item.0.strokeColor=UIColor.init(red: color, green: color, blue: color, alpha: 1.0).cgColor
            Draw.view?.layer.addSublayer(item.0)
        }
    }
    
    /*
     * 绘制网格线(画时间标尺)
     * @param dx - int ,指定滚动棒位置
     * @return void
     */
    static func grad(dx:Int,rect:CGRect)->Void {
        if Draw.drawGrad {
            // 删除垂直线网格
            for moveLayer in Draw.moveLayers{
                let theLayer = moveLayer.0
                moveLayer.1.removeAllPoints()
                theLayer.frame=CGRect(x:0, y:25, width:rect.width, height:rect.height-20-50)
                if (Draw.view?.layer.sublayers?.contains(theLayer))!{
                    theLayer.removeFromSuperlayer()
                }
            }
            // 删除时间轴刻度值
            for moveLayer in Draw.moveTextLayers{
                moveLayer.removeFromSuperlayer()
            }
            
            // 绘图区域高度
            let coordHeight = Draw.moveLayers[0].0.frame.height - 30
            let drawWidth = Draw.moveLayers[0].0.frame.width
            // 座标线间隔
            Draw.xSpace = 60 // 每像素10秒，10分钟=60个像素，画一短标尺
            let maxY = Draw.moveLayers[0].0.frame.minX + coordHeight-1
            let x = frameLeft
            let times = Int(drawWidth / CGFloat(Draw.xSpace))
            let startValue = dx % Draw.xSpace
            scrollX = dx
            // 绘制网格垂直线
            for i in 0...times {
                if Draw.moveTextLayers.count < i+1 {
                    // 水平刻度值 CATextLayer
                    let tLayer = CATextLayer()
                    let fontName:CFString = "Noteworthy-Light" as CFString
                    tLayer.font = CTFontCreateWithName(fontName, 9.0, nil)
                    tLayer.fontSize = 9.0
                    tLayer.foregroundColor = UIColor.black.cgColor
                    tLayer.contentsScale = UIScreen.main.scale
                    tLayer.alignmentMode = kCAAlignmentCenter
                    
                    Draw.moveTextLayers.append(tLayer)
                }
                
                let xe = x+i * Draw.xSpace - startValue
                if xe > x {
                    Draw.moveLayers[0].1.move(to: CGPoint(x:xe, y:0))
                    Draw.moveLayers[0].1.addLine(to: CGPoint(x:xe,y:Int(maxY)))
                    
                    let time = (dx/Draw.xSpace+i)*Draw.scales[Draw.scale] //每像素10秒，10分钟=60个像素，画一短标尺
                    let sHour = String(format:"%2d",time/6)
                    let sMinute = String(format:"%02d",(time%6)*10)
                    let s = "\(sHour):\(sMinute)"
                    
                    // 绘制座标轴刻度值
                    Draw.moveText(tLayer:Draw.moveTextLayers[i], x: CGFloat(xe-20), y: maxY+25.0, width: 40, height: 12, s: "\(s)")
                }
            }
            
            for moveLayer in Draw.moveLayers{
                let layer1:CAShapeLayer = moveLayer.0
                
                layer1.path=moveLayer.1.cgPath
                //填充颜色
                layer1.fillColor=UIColor.white.cgColor
                //边框颜色
                let color:CGFloat = moveLayer.2
                let acolor = UIColor.init(red: color, green: color, blue: color, alpha: 1.0)
                layer1.strokeColor=acolor.cgColor
                
                Draw.view?.layer.addSublayer(layer1)
            }
        }
    }
    
    /*
     * 绘制网格线(画时间标尺)
     * @param dx - int ,指定滚动棒位置
     * @return void
    static func drawRuleTime(dx:Int,rect:CGRect)->Void {
        xSpace = 60 // 每像素10秒，10分钟=60个像素，画一短标尺
        var interval = 6
        @unit = 1
        switch scale
            case 1
				xSpace = Draw.moveLayers[0].0.frame.width / 12
				interval = 3
				unit = 6
    when 2
				xSpace= Draw.moveLayers[0].0.frame.width / 12
				interval = 3
				unit = 12
    when 3
				@xSpace= Draw.moveLayers[0].0.frame.width / 12
				interval = 3
				@unit = 48
    else
				@xSpace = 60
				interval = 6
    y0 = @ruleTemperatureHeight
    y1 = @ruleTemperatureHeight+5
    @ctx.lineWidth = 1
    i = 0
    for sx in [@ruleTemperatureWidth...@ruleTimeWidth+@ruleTemperatureWidth+@offsetX] by @xSpace
    #@ctx.beginPath()
    linelen = 0
    x = sx - @offsetX
    unless i%(interval*@unit)
				s = ""
				linelen = 3
				if i < 60
    s += "0"
				s +=  (i/6).toString()+":00"
				@ctx.fillText s,x-15,y1+16 if x >= @ruleTemperatureWidth
    if x >= @ruleTemperatureWidth
				@ctx.beginPath()
				@ctx.moveTo x ,y0
				@ctx.lineTo x,y1+ linelen
				@ctx.strokeStyle = "rgba(0,0,0,0.5)"
				@ctx.stroke()
    
    @ctx.beginPath()
    if i is 0
				@ctx.moveTo sx,y0
				@ctx.lineTo sx,0
				@ctx.strokeStyle = "rgba(0,0,0,0.5)"
    else
				@ctx.moveTo x,y0
				@ctx.lineTo x,0
				@ctx.strokeStyle = "rgba(200,200,200,0.5)"
    @ctx.stroke()
    i+=@unit
     */
    
    // 画查看线
    static func drawSeeLine(x:CGFloat)->Int{
        Draw.moveLayers[2].1.move(to: CGPoint(x:x, y:Draw.moveLayers[2].0.frame.height-35))
        Draw.moveLayers[2].1.addLine(to: CGPoint(x:x, y:0))
        Draw.moveLayers[2].0.path=Draw.moveLayers[2].1.cgPath
        //填充颜色
        Draw.moveLayers[2].0.fillColor=UIColor.clear.cgColor
        //边框颜色
        let color:CGFloat = CGFloat(Draw.moveLayers[2].2)
        Draw.moveLayers[2].0.strokeColor=UIColor.init(red: color, green: color, blue: color, alpha: 1.0).cgColor
        Draw.view?.layer.addSublayer(Draw.moveLayers[2].0)
        return Int((Int(x)+scrollX)*10*Draw.scales[Draw.scale]/Draw.xSpace) // 返回当前平移和缩放参数下的 x 坐标(时间)
    }
    
    // 擦查看线
    static func removeSeeLine(x:CGFloat)->Void{
        Draw.moveLayers[2].0.removeFromSuperlayer()
        Draw.moveLayers[2].1.removeAllPoints()
    }
    
    // 画温度线
    static func temperature(recs:NSMutableArray)->Void{
        Draw.moveLayers[3].0.lineWidth = 1
        Draw.moveLayers[3].0.strokeColor = UIColor.red.cgColor
        Draw.moveLayers[4].0.lineWidth = 1
        Draw.moveLayers[4].0.strokeColor = UIColor.blue.cgColor
        let rote = Draw.scales[Draw.scale]// * 60 / Draw.xSpace
        var x:Int = 0
        var y:Int = 0
        var y1:Int = 0
        var firstDraw = true
        
        for rec in recs{
            let r = rec as! Dictionary<String, Any>
            let time = r["time"] as! Int
            
            // 如 time 在屏幕可视区域内，则绘制该点
            if time>scrollX*rote && time<scrollX*rote+frameWidth*rote{
                let t:Int = Int((r["temperature"] as! Int) >> 4)
                let t1:Int = Int((r["settingtemperature"] as! Int) >> 4)
                x = time/rote-scrollX+frameLeft
                y = frameHeight-(t+50)*coordSpace/10
                y1 = frameHeight-(t1+50)*coordSpace/10
                let pt = CGPoint(x:x,y:y)
                let pt1 = CGPoint(x:x,y:y1)
                if firstDraw==true{
                    firstDraw = false
                    Draw.moveLayers[3].1.move(to: pt)
                    Draw.moveLayers[4].1.move(to: pt1)
                }else{
                    Draw.moveLayers[3].1.addLine(to: pt)
                    Draw.moveLayers[4].1.addLine(to: pt1)
                }
            }
        }
        current_point = [x,y,y1]
        Draw.moveLayers[3].0.path=Draw.moveLayers[3].1.cgPath
        Draw.view?.layer.addSublayer(Draw.moveLayers[3].0)
        Draw.moveLayers[4].0.path=Draw.moveLayers[4].1.cgPath
        Draw.view?.layer.addSublayer(Draw.moveLayers[4].0)
    }
    
   /*
    func resize()->Void{
        let h = 450
        let w = $(@canvas).parent().width()
    @canvas[0].width = w
    @canvas[0].height = h
    @canvas[1].width = w- 50
    @canvas[1].height = h - 35
    @ruleTemperatureHeight = h - @ruleTimeHeight
    @ruleTimeWidth = w - @ruleTemperatureWidth
    @ctx = @canvas[0].getContext "2d"
    @ctxSee = @canvas[1].getContext "2d"
    @ctx.width = @ctx.width
    @drawRuleTemperature()
    @drawRuleTime()
    }

calcCoord:(rec)->
rote = @unit*60/@xSpace
t = rec.temperature >> 4
#x = (rec.time-@offsetX*@unit)/rote+@ruleTemperatureWidth
x = rec.time/rote-@offsetX+@ruleTemperatureWidth
y = @ruleTemperatureHeight-(t+50)*@space/10
t = rec.settingtemperature >> 4
y1 = @ruleTemperatureHeight-(t+50)*@space/10
[x,y,y1]

moveToPoint:(rec)->
@current_point = @calcCoord rec

_drawLine:(coord,whitch_line)->
@ctx.beginPath()
@ctx.moveTo @current_point[0],@current_point[whitch_line]
@ctx.lineTo coord[0],coord[whitch_line]
@ctx.strokeStyle = ["red","blue"][whitch_line-1]
@ctx.stroke()

drawToPoint:(rec)->
@ctx.lineWidth = 1
coord = @calcCoord rec
@_drawLine coord,1
@_drawLine coord,2
@current_point = coord

getScale:()->
@unit

setScale:(value)->
@scale = parseInt value
@resize()
@

setOffset:(value)->
@offsetX = parseInt value
@resize()
@
@current_point:[0,0,0]
 */
}
