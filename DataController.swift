//
//  DataController.swift
//  Dring
//
//  Created by 刘兴明 on 28/02/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {
    var name:String
    init(name:String) {
        self.name = name
    }
    
    func url()->String{
        return "http://www.yrr8.com/woo/index.php?cmd=\(self.name)"
    }
    
    func newRecord(data:[[String:AnyObject]]?)->Void{
        //获取管理的数据上下文 对象
        let context = ViewController().getContext()
        var table = NSEntityDescription.insertNewObject(forEntityName: self.name,
                                                        into: context)
        
        //对象赋值
        for item in data!{
            for rec in item{
                table.setValue(rec.value, forKey: rec.key)
            }
        }
        
        //保存
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        //AppDelegate().saveContext ()
    }
    
    func appendRecord(data:[[String:AnyObject]]?)->Void{
        //对象赋值
        for item in data!{
            //获取管理的数据上下文 对象
            let context = ViewController().getContext()
            var table = NSEntityDescription.insertNewObject(forEntityName: self.name,
                                                            into: context)
            for rec in item{
                //table.setValue(rec.value, forKey: rec.key)
                table.setPrimitiveValue(rec.value, forKey:rec.key )
            }
            //保存
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    // 取数据库实体属性
    func attributes()->[String]{
        let context = ViewController().getContext()
        let entity = NSEntityDescription.entity(forEntityName: self.name, in: context)
        var keys = [] as [String]
        for data in (entity?.attributesByName)!{
            keys.append(data.key)
        }
        return (keys)
    }
    
    
    func removeAll()-> Void {
        //let fetchRequest = NSFetchRequest<DryData>(entityName: self.name)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.name)
        do {
            let ctx = ViewController().getContext()
            var searchResults = try ctx.fetch(fetchRequest)
            for p in (searchResults ){
                ctx.delete(p as! NSManagedObject)
            }
        } catch  {
            print(error)
        }
    }
    
    /**
     * 返回实体中的全部记录
     * @param eachRecord - 回调函数,处理实体中的每一个记录
     * @return NSMutableArray 包含实体中所有记录的数组
     */
    func findAll(eachRecord:((AnyObject)->Void)?)-> NSMutableArray {
        //let fetchRequest = NSFetchRequest<DryData>(entityName: self.name)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.name)
        var resListData: NSMutableArray = NSMutableArray()
        do {
            let searchResults = try ViewController().getContext().fetch(fetchRequest)
            //print("numbers of \(searchResults.count)")
            
            for p in (searchResults ){
                var model:[String:Any] = [:]
                for attribute in attributes(){
                    model[attribute] = (p as AnyObject).value(forKey: attribute)
                }
                resListData.add(model)
                
                if ((eachRecord) != nil){
                    eachRecord!(p as AnyObject)
                }
                //print("id:  \((p as AnyObject).value(forKey: "mode")!) time: \((p as AnyObject).value(forKey: "time")!) temperature: \((p as AnyObject).value(forKey: "temperature")!)")
            }
        } catch  {
            print(error)
        }
        return resListData
    }
    
    func fetch(params:[String: Any]!) -> Bool{
        var p:[String: Any]! = params
        if p == nil{
            p = ["filter": self.attributes(),"token": ""]
        }
        Network.request(method: "GET", url: self.url(), params: p as Dictionary<String, AnyObject>, success: {(result) in
            self.appendRecord(data: result)
        }, failure: {(error) in
            print(error)
        })
        return true
    }
    
    func fetchDryData(mainid:String,params:[String: Any]!) -> Bool{
        let con1:Dictionary<String, Any> = ["field":"mainid","value":mainid,"operator":"eq"]
        //let condition = [con1]
        var p:[String: Any]! = params
        if p == nil{
            p = ["filter": ["id","time","settingtemperature","temperature","mode"],"cond":[con1]]
            //p["processData"] =  true
        }
        Network.request(method: "GET", url: self.url(), params: p, success: {(result) in
            self.removeAll()
            self.appendRecord(data: result)
            //通知名称常量
            let refresh = NSNotification.Name(rawValue:"refresh")
            let noti = NSNotification(name: refresh, object: self, userInfo: ["value":"DryData"])
            let notiCenter = NotificationCenter.default
            // 先注册通知监听者
            notiCenter.addObserver(self, selector: #selector(self.dataRefresh(noti:)), name: refresh, object: self)
            
            //延时2s
            sleep(2)
            // 发布通知
            notiCenter.post(noti as Notification)//之前直接使用Notification就没有这样as来转换了
            
        }, failure: {(error) in
            print(error)
        })
        return true
    }
    
    // selector是这样的
    func dataRefresh(noti: Notification) {
        ViewController().testNoti(noti: noti)
    }
    
    func getStart(sucess:(Array<Any>)->Void) ->Void{
        let fields = self.attributes()
        let condition = [["field":"state","value":0,"operator":"eq"]]
        //let token =  $.fn.cookie 'PHPSESSID'
        let p = ["cond":condition,"filter":fields,"token":""] as [String : Any]
        Network.request(method: "GET", url: self.url(), params: p as Dictionary<String, AnyObject>, success: {(result) in
            if (result?.count)! > 0{
                self.appendRecord(data: result)
            }
        }, failure: {(error) in
            print(error)
        })
    }
} //from everyang.net
