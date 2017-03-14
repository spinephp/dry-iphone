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
    
    func appendRecord(data:[[String:AnyObject]]?)->Void{
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
        AppDelegate().saveContext ()
    }
    
    func attributes()->[String]{
        let context = ViewController().getContext()
        let entity = NSEntityDescription.entity(forEntityName: self.name, in: context)
        var keys = [] as [String]
        for data in (entity?.attributesByName)!{
            keys.append(data.key)
        }
        
        return (keys)
    }
    
    func fetch(params:[String: Any]!) -> Bool{
        //condition = [{field:"state",value:"0",operator:"ne"}]
        var p:[String: Any]! = params
        if p == nil{
            p = ["filter": self.attributes(),"token": ""]
            //p["processData"] =  true
        }
        Network.request(method: "GET", url: self.url(), params: p as Dictionary<String, AnyObject>, success: {(result) in
            self.appendRecord(data: result)
        }, failure: {(error) in
            print(error)
        })
        return true
    }
    
    func fetchDryData(mainid:String,params:[String: Any]!) -> Bool{
        let con1:Dictionary<String, Any> = ["field":"mainid" as Any,"value":mainid as Any,"operator":"eq" as Any]
        //let condition = [con1]
        var p:[String: Any]! = params
        if p == nil{
            p = ["filter": ["id","time","settingtemperature","temperature","mode"],"cond":[con1]]
            //p["processData"] =  true
        }
        Network.request(method: "GET", url: self.url(), params: p, success: {(result) in
            self.appendRecord(data: result)
        }, failure: {(error) in
            print(error)
        })
        return true
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
