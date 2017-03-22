//
//  DryDataRefresh.swift
//  Dring
//
//  Created by 刘兴明 on 16/03/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import Foundation
import UIKit

class MyObserver: NSObject {
    
    var name:String = ""
    
    init(name:String,event:NSNotification.Name){
        super.init()
        
        self.name = name
        NotificationCenter.default.addObserver(self, selector:#selector(didMsgRecv(notification:)),
                                               name: event, object: nil)
    }
    
    //通知处理函数
    func didMsgRecv(notification:NSNotification){
        print("didMsgRecv: \(notification.userInfo)")
    }
    
    deinit {
        //记得移除通知监听
        NotificationCenter.default.removeObserver(self)
    }
    
}
