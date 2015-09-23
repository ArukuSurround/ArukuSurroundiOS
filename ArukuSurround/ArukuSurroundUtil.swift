//
//  ArukuSurroundUtil.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/19.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import Foundation

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
    
    // 接続中のJINS MEME
    static var currentPeripheral:CBPeripheral! = nil
    
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
        
        //匿名ユーザー作成
        ArukuSurroundUtil.createAnonymousUser()
        
        //MEMEをコントロールするクラス
        utilDelegate = ArukuSurroundUtilMEMEDelegate();
        utilDelegate.setting = setting;
        //セーブ毎に変更する UUIDを設定する
        utilDelegate.saveLogUuid = NSUUID().UUIDString
            
        memeController = MEMEController()
        memeController?.delegate = utilDelegate;
    }
    
    /** 匿名ユーザー作成
    *
    */
    static func createAnonymousUser(){
        let user:NCMBUser? = NCMBUser.currentUser()
        if user != nil {
            //print("ログイン中: \(user)")
        }
        else {
            //print("ログインしていない")
            //匿名ユーザー登録
            NCMBAnonymousUtils.logInWithBlock({ (NCMBUser user, NSError error) -> Void in
                if error == nil {
                    //print("user\(user)")
                }
                else{
                    //print("error\(error)")
                }
            })
        }
    }
    
    /** Twitterアカウントでログイン
    *
    * @param callback ログイン結果を通知するBlocks
    *
    */
    static func loginTwitter(callback: ((user:NCMBUser?,error:NSError?)->Void)){        
        //Twitterでログイン処理をする
        NCMBTwitterUtils.logInWithBlock({(user: NCMBUser!, error: NSError!) -> Void in
            if let u = user {
                if u.isNew {
                    //print("Twitterで登録成功")
                    callback(user:u,error:nil)
                }
                else{
                    //print("Twitterでログイン成功!")
                    callback(user:u,error:nil)
                }
            }
            else {
                //print("Twitterログインがキャンセルされた.")
                callback(user:nil,error:error)
            }
        })
    }
    
    /** ログイン状態を取得
    *
    */
    static func isLogin(callback: ((user:NCMBUser?)->Void)){
        //ログイン中のユーザーを取得
        let currentUser:NCMBUser? = NCMBUser.currentUser()
        if currentUser != nil {
            //ログイン中
            //設定値をロードする
            loadSetting({ (setting, error) -> Void in
                self.setting = setting;
                self.utilDelegate?.setting = setting;
                
                print("loadSetting:\(setting)")
            })
            
            callback(user:currentUser)
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
    static func saveSetting(setting:ArukuSurroundSetting){
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
                        }
                        else {
                            print("[UPDATE-ERROR] \(saveError)");
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
    
    /** 保存済みの設定値をロードする
    *
    */
    static func loadSetting(callback: ((setting:ArukuSurroundSetting?,error:NSError?)->Void)){
        let className = "Setting"

        let currentUser:NCMBUser = NCMBUser.currentUser()
        
        let query:NCMBQuery = NCMBQuery.init(className: className)
        query.whereKey ("user",equalTo:currentUser)
        query.findObjectsInBackgroundWithBlock( { (NSArray objects, NSError error) in
            
            let obj:NCMBObject = objects[0] as! NCMBObject
            let s:ArukuSurroundSetting = ArukuSurroundSetting(object: obj)
            
            //検索結果をコールバックする
            callback(setting:s, error: error)
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
    
    /** JINS MEME の 検索 & 接続
    *
    */
    static func startScanningMeme(){
        print("startScanningMeme");
        memeController?.startScanningMeme();
    }
    
    
    /** 歩くの処理を開始
    *
    */
    static func startWalk(){
        print("startWalk");
        //セーブ毎に変更する UUIDを設定する
        utilDelegate.saveLogUuid = NSUUID().UUIDString
        
        //JINS MEME の 検索 & 接続
        startScanningMeme()
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
    var latitude:Double?
    
    //緯度
    var longitude:Double?
    
    //歩行ステータス
    var walkStatus:Int?
    
    //歩数
    var stepCount:Int?
    
    //TODO: MEMEからの生データを保存すると詳細ログを解析できる
}
