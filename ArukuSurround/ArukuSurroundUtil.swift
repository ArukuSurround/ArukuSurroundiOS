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
    static var utilDelegate:ArukuSurroundUtilMEMEDelegate?
    
    //各種設定をロードして保持する
    static var setting:ArukuSurroundSetting!
    
    //JINS MEMEをコントロールするクラス
    static var memeController:MEMEController!
    
    // 接続中のJINS MEME
    static var currentPeripheral:CBPeripheral!
    
    override init(){
        super.init()
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
        utilDelegate?.setting = setting;
        
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
                        obj.setObject(log.walk_status, forKey: "walkStatus")
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
                        obj.setObject(log.user, forKey: "user")
                        obj.setObject(log.latitude, forKey: "latitude")
                        obj.setObject(log.longitude, forKey: "longitude")
                        obj.setObject(log.walk_status, forKey: "walkStatus")
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
    
    /** JINS MEME の 検索
    *
    */
    static func startScanningMeme(){
        print("startScanningMeme");
        memeController?.startScanningMeme();
    }

}

class ArukuSurroundUtilMEMEDelegate:MEMEControllerDelegate {
    
    //キョロキョロ(首を振っているか)判定の為の値
    var lodYaw: Float = 0
    
    //キョロキョロしているか？の判定用カウンタ
    var lookingAroundCount:Int = 0
    
    //姿勢が悪いか？の判定用カウンタ
    var badPostureCount:Int = 0
    
    //走っているか？の判定用カウンタ
    var runningCount:Int = 0
    
    //歩行中ステータス列挙型
    enum Condition {
        case Walking //歩行
        case Running //走っている
        case BadPosture //姿勢が悪い
        case Speepy //眠気
        case LookingAround //キョロキョロしている
    }
    
    //現在の歩行ステータスを保存する
    var currentCondition:Condition = .Walking
    
    //歩行中か走っているかの判定用のタイムスタンプ
    var lastStepTimestamp:NSDate = NSDate()
    
    //各種設定をロードして保持する
    var setting:ArukuSurroundSetting!
    
    /** スキャン結果受信デリゲート
    *
    * @param peripheral スキャンされたJINS MEME
    *
    */
    @objc func memePeripheralFound(peripheral: CBPeripheral!){
        print("memePeripheralFound \(peripheral)")
        // UUID決め打ちでつなぐ
        /*
        if peripheral.identifier.UUIDString == MEME_DEVICE_UUID {
            MEMEController.connectPeripheral(peripheral);
        }
        */
    }
    
    /** JINS MEMEとの切断を受け取る
    *
    * @param peripheral 切断されたJINS MEME
    *
    */
    @objc func memePeripheralDisconneted(peripheral:CBPeripheral){
        print("memePeripheralDisconneted \(peripheral)")
    }
    
    /** MEME リアルタイムモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    @objc func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!){
        //歩くスピードで SE を変更したりする
        //print("memeRealTimeModeDataReceived \(data)")
        
        doWalking(data)
    }
    
    
    /** 歩行中の処理
    *
    * @param data MEMEから取得したリアルタイムデータ
    *
    */
    func doWalking(data: MEMERealTimeData){
        //歩行中かのステータスを確認
        if data.isWalking != 1 {
            return
        }
        
        //初期値は 歩行中 とする
        currentCondition = .Walking
        
        //姿勢を表す角度で歩いていか走っているかの判定をする
        if data.pitch > 25 {
            badPostureCount += 1
        }
        else{
            badPostureCount = 0;
        }
        if badPostureCount > 3 {
            //前傾姿勢が長く長く続くと 悪い姿勢 とする
            currentCondition = .BadPosture
        }
        
        //キョロキョロしているか判定する
        if currentCondition == .Walking {
            //data.yaw
            var tmp:Float = data.yaw - lodYaw
            if tmp < 0{
                tmp = tmp * -1
            }
            
            if tmp > 5.0 {
                lookingAroundCount += 1
            }
            else{
                lookingAroundCount = 0
            }
            lodYaw = data.yaw
            
            if lookingAroundCount > 2 {
                //キョロキョロしている事にする
                currentCondition = .LookingAround
            }
        }
        
        if currentCondition == .Walking {
            //走っているかの判定
            if Double(NSDate().timeIntervalSinceDate(lastStepTimestamp)) < 0.5{
                runningCount += 1
            }
            else{
                runningCount = 0
            }
            lastStepTimestamp = NSDate()
            
            if runningCount > 2 {
                //間隔が短いので走っている事にする
                currentCondition = .Running
            }
        }
        
        print("doWalking currentCondition:\(currentCondition)")
        
        
        // currentCondition で 歩行中SEの変更
        switch currentCondition {
        case .Running:
            SoundEffectUtil.play("running")
        case .BadPosture:
            SoundEffectUtil.play("poison")
        case .LookingAround:
            SoundEffectUtil.play("looking_around")
        default:
            SoundEffectUtil.play("coin")
        }
        
    }

    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    @objc func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!){
        print("memeStandardModeDataReceived \(data)")
        
        //TODO: 眠気のステータスを確認
        if data.sleepy  == MEME_FCS_A_LITTLE {
            //少し眠い
            
        }
        else if data.sleepy  == MEME_FCS_VERY {
            //大変眠い
            
        }
        
    }
}

/** 各設定値
*
*/
class ArukuSurroundSetting {
    
    //ユーザー
    var user:NCMBUser!
    
    //BOCCO room_id
    var bocco_room_id:String?

    //BOCCO ユーザーアクセストークン
    var bocco_access_token:String?
    
    //JINS MEMEの識別子
    var jins_meme_device_uuid:String?
    
    //イニシャライザ
    init(){
        
    }
    
    //イニシャライザ
    init(object:NCMBObject){
        user = object.objectForKey("user") as! NCMBUser
        bocco_room_id = object.objectForKey("boccoRoomId") as? String
        bocco_access_token = object.objectForKey("boccoAccessToken") as? String
        jins_meme_device_uuid = object.objectForKey("jinsMemeDeviceUuid") as? String
    }
}

/** 歩行ログ
*
*/
class ArukuSurroundWalkLog {
    //ユーザー
    var user:NCMBUser!
    
    //緯度
    var latitude:Double?
    
    //緯度
    var longitude:Double?
    
    //歩行ステータス
    var walk_status:Int?
}
