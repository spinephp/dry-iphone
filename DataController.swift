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
            var attrs = attributes()
            for rec in item{
                //table.setValue(rec.value, forKey: rec.key)
                if attrs.index(of: rec.key)! >= 0{
                    table.setPrimitiveValue(rec.value, forKey:rec.key )
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
    
    /**
     * 实体中的记录格式转换成 NSMutableArray
     * @param records - 实体中的记录
     * @return [Any] 记录转换后的数组
     */
    func recordToArray(records:[[String:AnyObject]]?,eachRecord:((AnyObject)->Void)?)-> [Any] {
        var resListData: [Any] = []
        do {
            for p in records!{
                var model:[String:Any] = [:]
                for attribute in attributes(){
                    model[attribute] = (p as AnyObject).value(forKey: attribute)
                }
                resListData.append(model)
                if ((eachRecord) != nil){
                    eachRecord!(p as AnyObject)
                }
            }
        } catch  {
            print(error)
        }
        return resListData
    }
    
    /**
     * 返回实体中的指定记录
     * @param id - 记录中的关键字段
     * @return [String:Any] 查到的实体中的记录
     */
    func find(id:Int)-> [String:Any] {
        //let fetchRequest = NSFetchRequest<DryData>(entityName: self.name)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.name)
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "id = \(id)", "")
        fetchRequest.predicate = predicate
        
        var model:[String:Any] = [:]
        do {
            let searchResults = try ViewController().getContext().fetch(fetchRequest)
            let p = searchResults[0]
            
            for attribute in attributes(){
                model[attribute] = (p as AnyObject).value(forKey: attribute)
            }
        } catch  {
            print(error)
        }
        return model
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
}
