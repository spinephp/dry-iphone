//
//  Network.swift
//  Dring
//
//  Created by 刘兴明 on 26/02/2017.
//  Copyright © 2017 刘兴明. All rights reserved.
//

import Foundation

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

class Network{
    
    /**
     * 向服务器发送请求
     * @param
     *     method - String 类型，指定请求方法
     *     url - String 类型，指定请求路径
     *     params - Dictionary<String, Any> 类型，指定请求参数
     *     success - String 类型，指定成功调用后的回调函数
     *     failure - String 类型，指定失败调用后的回调函数
     * @return
     *     Void
     */
    static func request(method: String, url: String, params: Dictionary<String, Any> = Dictionary<String, Any>(),success:@escaping ((_ result:[[String:AnyObject]]?) -> ()),failure: @escaping ((_ error:Error) -> ())) {
        let session = URLSession.shared
        
        var newURL = url
        if method == "GET" {
            newURL += "&" + Network().buildParams(params)
        }
        
        var request = URLRequest(url: URL(string: newURL)! as URL)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if method == "POST" {
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = Network().buildParams(params).data(using: String.Encoding.utf8)
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if let response = response as? HTTPURLResponse {
                print("code\(response.statusCode)")
                for (tab, result) in response.allHeaderFields {
                    print("\(tab.description) - \(result)")
                }
                if response.statusCode == 200 && (data != nil){
                    //JSON解析， 做逻辑
                    let responseStr = String(data: data!,
                                             encoding: String.Encoding.utf8)
                    let jsonData = responseStr?.data(using: String.Encoding.utf8, allowLossyConversion: false)
                    let userArray = try? JSONSerialization.jsonObject(with: jsonData!,
                                                                      options: .allowFragments) as? [[String: AnyObject]]
                    DispatchQueue.main.async(execute: {
                        success(userArray!)
                    })
                } else {
                    //通知UI接口执行失败
                    DispatchQueue.main.async(execute: {
                        
                        failure(error!)
                    })
                }
            }
        })
        task.resume()
    }
    
    /**
     * 请求体,并处理特殊字符串 !$&'()*+,;= :#[]@
     * @param
     *     parameters - [String: Any] 类型，指定要处理参数数组
     * @return
     *     String, 参数处理后的编码串
     */
    private func buildParams(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    /**
     * 转换参数键值对，为对应的串对数组
     * @param
     *     key - String 类型，指定要处理的键
     *     value - Any 类型，指定要处理的值
     * @return
     *     [(String,String)] 处理后的键值编码数组
     */
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for (index,value) in array.enumerated() {
                var key1:String
                if let dictionary = value as? [String: Any] {
                    key1 = "\(key)[\(index)]"
                }else{
                    key1 = "\(key)[]"
                }
                components += queryComponents(fromKey: "\(key1)", value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape((value.boolValue ? "1" : "0"))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape((bool ? "1" : "0"))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    /**
     * 对给定的串进行编码
     * @param
     *     string - String 类型，指定要处理的串
     * @return
     *     String 编码后的串
     */
    public func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
    
}
