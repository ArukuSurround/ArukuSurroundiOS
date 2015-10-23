//
//  BoccoAPI.swift
//  BoccoLibSample
//
//  Created by 古川信行 on 2015/09/03.
//  Copyright (c) 2015年 古川信行. All rights reserved.
//

import Foundation

public class BoccoAPI {

    //BOCCOサーバURL
    private static var API_HOST_URL = "https://api.bocco.me/1/rooms/{room_id}/messages";
    
    /** 既存のメッセージの取得
     *
     * @param room_id ルームID
     * @param access_token アクセストークン
     *
     */
    static func getMessages(room_id:String,access_token:String, callback:(NSArray?)->Void){
    
        let url:String = (API_HOST_URL+"?access_token="+access_token).stringByReplacingOccurrencesOfString("{room_id}", withString: room_id)
        //print("url:\(url)")
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        
        let taskRequest = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { data, response, error in
            if (error == nil) {
                let result:NSArray = responseToNSArray(data!)
                //コールバック
                callback(result)                
            } else {
                //エラー
                print(error)
                callback(nil)
            }
        })
        taskRequest.resume()
    }
    
    /** レスポンスをJSON形式として変換
     *
     */
    private static func responseToNSArray(response:NSData) -> NSArray! {
        do {
            let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.MutableContainers)
            if jsonObject is NSArray {
                return(jsonObject as! NSArray)
            }
            else{
                return(nil)
            }
        } catch {
            return(nil)
        }
    }
    
    
    /** テキストメッセージを送信
     *
     */
    public static func postMessageText(room_id:String, access_token:String, text:String, callback:(NSDictionary?)->Void){
        
        //POST先URL作成
        let url = API_HOST_URL.stringByReplacingOccurrencesOfString("{room_id}", withString: room_id)
        print("url:\(url)")
        
        //ユニークIDを生成
        let unique_id:String =  NSUUID().UUIDString;
        
        //POSTパラメータを作成
        let params = "access_token="+access_token+"&media=text"+"&text="+text+"&unique_id="+unique_id
        let postData = params.dataUsingEncoding(NSUTF8StringEncoding)
        
        //print("postData:\(postData)")
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postData
        
        let taskRequest = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { data, response, error in
            if (error == nil) {
                let result:NSDictionary = responseToNSDictionary(data!)
                //コールバック
                callback(result)
            } else {
                //エラー
                print(error)
                callback(nil)
            }
        })
        taskRequest.resume()
    }
    
    /** レスポンスをJSON形式として変換
    *
    */
    private static func responseToNSDictionary(response:NSData) -> NSDictionary! {
        do {
            let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.MutableContainers)
        
            if jsonObject is NSDictionary {
                return(jsonObject as! NSDictionary)
            }
            else{
                return(nil)
            }
        } catch {
            return(nil)
        }
    }
}
