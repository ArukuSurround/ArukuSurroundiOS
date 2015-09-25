//
//  ArukuSurroundUtil.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/19.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import Foundation
import UIKit

/** ArukuSurround に関する処理を纏めたクラス
*
*/
class ArukuSurroundUtil:NSObject {
    //MMEMの状態通知デリゲート
    static var utilDelegate:ArukuSurroundUtilMEMEDelegate!
    
    //各種設定をロードして保持する
    static var setting:ArukuSurroundSetting!
    
    //JINS MEMEをコントロールするクラス
    static var memeController:MEMEController!
        
    /** イニシャライザ
    *
    */
    override init(){
        super.init()
    }
    
    /** メインスレッドで実行する
    *
    * @param block メインスレッドで実行する処理
    *
    */
    static func dispatch_async_main(block: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }

    /** アプリケーション起動時の初期化 処理
    *
    */
    static func didFinishLaunchingWithOptions() {
        //オーディオセッション 初期設定
        SoundEffectUtil.initAudioSession()

        //nifty mBaaS の 初期化
        NCMB.setApplicationKey(Config.NCMB_APPLICATION_KEY, clientKey: Config.NCMB_CLIENT_KEY)

        //Twitterログインの為の初期化
        NCMBTwitterUtils.initializeWithConsumerKey(Config.TWITTER_API_KEY, consumerSecret: Config.TWITTER_API_SECRET)
        
        //MEMEをコントロールするクラス
        utilDelegate = ArukuSurroundUtilMEMEDelegate();
        utilDelegate.setting = setting;
        //セーブ毎に変更する UUIDを設定する
        utilDelegate.saveLogUuid = NSUUID().UUIDString
            
        memeController = MEMEController()
        memeController?.delegate = utilDelegate;
    }
        
    /** Twitterアカウントでログイン
    *
    * @param callback ログイン結果を通知するBlocks
    *
    */
    static func loginTwitter(callback: ((user:NCMBUser?,error:NSError?)->Void)){
        print("loginTwitter")
        //Twitterでログイン処理をする
        NCMBTwitterUtils.logInWithBlock({(user: NCMBUser!, error: NSError!) -> Void in
            if let u = user {                
                //ログイン中 なので 設定値をロードする
                loadSetting({ (setting, error) -> Void in
                    if u.isNew {
                        print("Twitterで登録成功")
                    }
                    
                    self.setting = setting;
                    self.utilDelegate?.setting = setting;
                    
                    //ログイン中のユーザーを取得
                    let currentUser:NCMBUser? = NCMBUser.currentUser()
                    if NCMBTwitterUtils.isLinkedWithUser(currentUser) == true {
                        //Twitterアカウントの関連付け済み
                        callback(user:currentUser,error:nil)
                    }
                    else{
                        NCMBTwitterUtils.linkUser(currentUser, block: { (error) -> Void in
                            print("linkUser error:\(error)")
                            if NCMBTwitterUtils.isLinkedWithUser(currentUser) {
                                //Twitterアカウントの関連付け成功
                                callback(user:currentUser,error:nil)
                            }
                            else{
                                //失敗
                                callback(user:nil,error:error)
                            }
                        })
                    }
                })
            }
            else {
                print("Twitterログインがキャンセルされた.")
                callback(user:nil,error:error)
            }
        })
    }
    
    /** ログイン状態を取得
    *
    */
    static func isLogin(callback: ((user:NCMBUser?)->Void)){
        print("isLogin")
        
        //ログイン中のユーザーを取得
        let currentUser:NCMBUser? = NCMBUser.currentUser()
        if currentUser != nil {
            //匿名ユーザーは設定済み
            //Twitter連動しているか確認する
            let isLinked:Bool = NCMBTwitterUtils.isLinkedWithUser(currentUser)
            print("isLinked:\(isLinked)")
            
            if isLinked == true {
                //ログイン中 なので 設定値をロードする
                loadSetting({ (setting, error) -> Void in
                
                    self.setting = setting;
                    self.utilDelegate?.setting = setting;
                
                    //ロードに成功してからコールバック
                    callback(user:currentUser)
                })
            }
            else{
                //Twitterと未連動なので 未ログイン扱い
                callback(user:nil)
            }
        }
        else{
            //ログインしてなかった場合
            callback(user:nil)
        }
    }
    
    /** 匿名ユーザー削除
    * 匿名ユーザーを削除する場合に利用する
    */
    static func deleteAnonymousUser(){
        NCMBUser.logOut()
    }
    
    /** ログイン中のユーザーを取得する
    *
    */
    static func currentUser() -> NCMBUser {
        return NCMBUser.currentUser()
    }
    
    /** 各設定値の保存
    *
    */
    static func saveSetting(setting:ArukuSurroundSetting, callback:((error:NSError?)->Void)){
        let className = "Setting"
        var saveError:NSError?

        //ログイン中のユーザーを設定
        setting.user = NCMBUser.currentUser()
        
        if setting.user != nil {
            //保存済みの場合は更新する
            let query:NCMBQuery = NCMBQuery.init(className: className)
            query.whereKey ("user",equalTo:setting.user)
            query.findObjectsInBackgroundWithBlock( { (NSArray objects, NSError error) in
                if error == nil {
                    if objects.count > 0 {
                        //更新
                        let obj:NCMBObject = objects[0] as! NCMBObject
                        obj.setObject(setting.bocco_room_id, forKey: "boccoRoomId")
                        obj.setObject(setting.bocco_access_token, forKey: "boccoAccessToken")
                        obj.setObject(setting.jins_meme_device_uuid, forKey: "jinsMemeDeviceUuid")
                        obj.save(&saveError)
                        if saveError == nil {
                            print("[UPDATE] Done")
                            callback(error:nil)
                        }
                        else {
                            print("[UPDATE-ERROR] \(saveError)");
                            
                            callback(error:saveError)
                        }
                    }
                    else{
                        //新規作成
                        let obj:NCMBObject = NCMBObject.init(className:className)
                        obj.setObject(setting.user, forKey: "user")
                        obj.setObject(setting.bocco_room_id, forKey: "boccoRoomId")
                        obj.setObject(setting.bocco_access_token, forKey: "boccoAccessToken")
                        obj.setObject(setting.jins_meme_device_uuid, forKey: "jinsMemeDeviceUuid")
                        obj.save(&saveError)
                        if saveError == nil {
                            print("[SAVE] Done")
                            callback(error:nil)
                        }
                        else {
                            print("[SAVE-ERROR] \(saveError)");
                            callback(error:saveError)
                        }
                    }
                }
                else{
                    print("[QUERY-ERROR] \(error)");
                }
            })
        }
    }
    
    /** 保存済みの設定値をロードする
    *
    */
    static func loadSetting(callback: ((setting:ArukuSurroundSetting?,error:NSError?)->Void)){
        let className = "Setting"
        let currentUser:NCMBUser = NCMBUser.currentUser()
        
        let query:NCMBQuery = NCMBQuery.init(className: className)
        query.whereKey ("user",equalTo:currentUser)
        query.findObjectsInBackgroundWithBlock( { (NSArray objects, NSError error) in
            
            if error == nil && objects != nil && objects.count > 0 {
                let obj:NCMBObject = objects[0] as! NCMBObject
                let s:ArukuSurroundSetting = ArukuSurroundSetting(object: obj)
            
                //検索結果をコールバックする
                callback(setting:s, error: nil)
            }
            else{
                //エラー
                callback(setting:nil, error: error)
            }
            
        })
    }
    
    //移動ログをサーバに保存
    static func saveWalkLog(log:ArukuSurroundWalkLog){
        let className = "WalkLog"
        var saveError:NSError?
        
        //ログイン中のユーザーを設定
        log.user = NCMBUser.currentUser()
        
        if log.user != nil {
            //保存済みの場合は更新する
            let query:NCMBQuery = NCMBQuery.init(className: className)
            query.whereKey ("uuid",equalTo:log.uuid)
            query.whereKey ("user",equalTo:log.user)
            query.whereKey ("latitude",equalTo:log.latitude)
            query.whereKey ("longitude",equalTo:log.longitude)
            
            query.findObjectsInBackgroundWithBlock( { (NSArray objects, NSError error) in
                if error == nil {
                    if objects.count > 0 {
                        //更新
                        let obj:NCMBObject = objects[0] as! NCMBObject
                        //obj.setObject(log.latitude, forKey: "latitude")
                        //obj.setObject(log.longitude, forKey: "longitude")
                        obj.setObject(log.walkStatus, forKey: "walkStatus")
                        obj.setObject(log.stepCount, forKey: "stepCount")
                        obj.save(&saveError)
                        if saveError == nil {
                            print("[UPDATE] Done")
                        }
                        else {
                            print("[UPDATE-ERROR] \(saveError)");
                        }
                    }
                    else{
                        //新規作成
                        let obj:NCMBObject = NCMBObject.init(className:className)
                        obj.setObject(log.uuid, forKey: "uuid")
                        obj.setObject(log.user, forKey: "user")
                        obj.setObject(log.latitude, forKey: "latitude")
                        obj.setObject(log.longitude, forKey: "longitude")
                        obj.setObject(log.walkStatus, forKey: "walkStatus")
                        obj.setObject(log.stepCount, forKey: "stepCount")
                        obj.save(&saveError)
                        if saveError == nil {
                            print("[SAVE] Done")
                        }
                        else {
                            print("[SAVE-ERROR] \(saveError)");
                        }
                    }
                }
                else{
                    print("[QUERY-ERROR] \(error)");
                }
            })
        }
    }
    
    /** 歩行ログを集計
    *
    * @param logUuid セーブ毎にユニークな ID
    * @param callback 集計結果をコールバックする
    */
    static func aggregateWalkLog(logUuid:String,callback: ((data:NSDictionary)->Void)){
        let className = "WalkLog"
        
        //ログイン中のユーザーを設定
        let user:NCMBUser = NCMBUser.currentUser()
        
        let query:NCMBQuery = NCMBQuery.init(className: className)
        query.whereKey("uuid",equalTo:logUuid)
        query.whereKey("user",equalTo:user)
        query.orderByDescending("stepCount")
        query.findObjectsInBackgroundWithBlock( { (NSArray objects, NSError error) in
            if error == nil {
                if objects.count > 0 {
                    //歩いた歩数
                    let obj:NCMBObject = objects[0] as! NCMBObject
                    let stepCount:Int = obj.objectForKey("stepCount") as! Int
                    //print("stepCount:\(stepCount)");
                    
                    //TOTO: 走ったトータル時間
                    //TOTO: 姿勢が悪かったトータル時間
                    //TODO: 眠気のあったトータル時間
                    
                    //集計結果をコールバックする
                    let data:NSDictionary = ["stepCount":stepCount]
                    callback(data:data)
                }
                else{
                    //集計対象のレコードが無かった
                }
            }
            else{
               print("[QUERY-ERROR] \(error)");
            }
        })
    }
    
    /** 歩くの処理を開始
    *
    */
    static func startWalk(viewMemeDelegate:ArukuSurroundMEMEControllerDelegate){
        print("startWalk");
        //セーブ毎に変更する UUIDを設定する
        utilDelegate.saveLogUuid = NSUUID().UUIDString
        
        //JINS MEMEのイベントを受け取るビューを設定
        utilDelegate?.viewMemeDelegate = viewMemeDelegate
        
        //JINS MEME の 検索 & 接続
        memeController?.startScanningMeme()
    }

    /** 歩く処理を終了
    *
    */
    static func endWalk(){
        print("endWalk");
        // BOCCOにメッセージを送る為の処理をする
        // utilDelegate.saveLogUuid をキーに集計
        aggregateWalkLog(utilDelegate.saveLogUuid,callback: {(data) -> Void in
            //サーバ側で現在までの歩数やステータスを取得 集計
            
            let stepCount:Int = data.objectForKey("stepCount") as! Int
            
            //TODO: 集計結果にあったメッセージをBOCCOに送る
            let text:String = "今回の歩数は \(stepCount)歩でした。次回もがんばって!"
            
            BoccoAPI.postMessageText( setting.bocco_room_id!, access_token: setting.bocco_access_token!, text: text,
                callback: { (result) -> Void in
                
            })
        })
    }
    
    
    /** アラートを表示
    *
    * @param title アラートのタイトル
    * @param message アラートのメッセージ
    * @param btnTitle ボタンのタイトル
    * @param callback OKを押した結果のコールバック
    *
    */
    static func showAlert(vc:UIViewController,title:String,message:String,btnTitle:String,callback:(()-> Void)){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let otherAction = UIAlertAction(title: btnTitle, style: .Default) {
            action in
            callback()
        }
        alertController.addAction(otherAction)
        
        vc.presentViewController(alertController, animated: true, completion: nil)
    }
    
    /** 確認アラートを表示
    *
    * @param title アラートのタイトル
    * @param message アラートのメッセージ
    * @param btnCancelTitle キャンセルボタンのタイトル
    * @param cancelCallback キャンセルを押した結果のコールバック
    * @param btnOkTitle OKボタンのタイトル
    * @param OkCallback OKを押した結果のコールバック
    *
    */
    static func showConfirm(vc:UIViewController,title:String,message:String,btnCancelTitle:String,cancelCallback:(()-> Void),btnOkTitle:String,okCallback:(()-> Void)){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        //Cancelボタン設定
        let cancelAction = UIAlertAction(title: btnCancelTitle, style: .Default) {
            action in
            cancelCallback()
        }
        alertController.addAction(cancelAction)
        
        //Okボタン設定
        let okAction = UIAlertAction(title: btnOkTitle, style: .Default) {
            action in
            okCallback()
        }
        alertController.addAction(okAction)
        
        vc.presentViewController(alertController, animated: true, completion: nil)
    }
}


/** 歩行ログ
*
*/
class ArukuSurroundWalkLog {
    
    //ログ識別
    var uuid:String!
    
    //ユーザー
    var user:NCMBUser!
    
    //緯度
    var latitude:Double!
    
    //緯度
    var longitude:Double!
    
    //歩行ステータス
    var walkStatus:Int!
    
    //歩数
    var stepCount:Int!
    
    //LV
    var lv:Int!
    
    //MEMEの電池残量
    var powerLeft:UInt8!
    
    //TODO: MEMEからの生データを保存すると詳細ログを解析できる
}
