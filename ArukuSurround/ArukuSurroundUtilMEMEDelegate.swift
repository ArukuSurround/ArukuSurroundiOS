//
//  ArukuSurroundUtilMEMEDelegate.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/22.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import Foundation

class ArukuSurroundUtilMEMEDelegate:MEMEControllerDelegate {
    
    //JINS MEMEのイベントの通知先 ビュー
    var viewMemeDelegate:ArukuSurroundMEMEControllerDelegate!
    
    //セーブ毎に変更されるユニークキー
    var saveLogUuid:String!
    
    //歩行中ステータス列挙型
    enum Condition:Int {
        case Walking //歩行
        case Running //走っている
        case BadPosture //姿勢が悪い
        case LookingAround //キョロキョロしている
        case Speepy //眠気
    }
    
    //歩数
    var stepCount: Int = 0
    
    //キョロキョロ(首を振っているか)判定の為の値
    var lodYaw: Float = 0
    
    //キョロキョロしているか？の判定用カウンタ
    var lookingAroundCount:Int = 0
    
    //姿勢が悪いか？の判定用カウンタ
    var badPostureCount:Int = 0
    
    //走っているか？の判定用カウンタ
    var runningCount:Int = 0
    
    //現在の歩行ステータスを保存する
    var currentCondition:Condition = .Walking
    
    //歩行中か走っているかの判定用のタイムスタンプ
    var lastStepTimestamp:NSDate = NSDate()
    
    //各種設定をロードして保持する
    var setting:ArukuSurroundSetting!
    
    // 接続中のJINS MEME
    var currentPeripheral:CBPeripheral! = nil
    
    //DEMO用ロケーション
    var demoCurrentLocation: CLLocationCoordinate2D!
    
    /** 各カウンターをリセットする
    *
    */
    func reset(){
        stepCount = 0
        lookingAroundCount = 0
        badPostureCount = 0
        runningCount = 0
        demoCurrentLocation = nil
        currentCondition = .Walking
    }
    
    /** スキャン結果受信デリゲート
    *
    * @param peripheral スキャンされたJINS MEME
    *
    */
    @objc func memePeripheralFound(peripheral: CBPeripheral!){
        print("memePeripheralFound \(peripheral)")
        
        if peripheral.state == .Disconnected {
            //UUID決め打ちでつなぐ
            //TODO: 一度でも繋いだ事があると 勝手に繋がる...。(この仕様はバグの原因じゃないかなー
            if setting.jins_meme_device_uuid?.characters.count == 0 || peripheral.identifier.UUIDString == setting.jins_meme_device_uuid {
                print("connectPeripheral \(peripheral)")
                MEMEController.connectPeripheral( peripheral );
            }
        }
        
        if viewMemeDelegate != nil {
            viewMemeDelegate?.memePeripheralFound(peripheral)
        }
    }
    
    /** JINS MEMEへの接続完了
    *
    * @param peripheral 接続されたJINS MEME
    *
    */
    @objc func memePeripheralConnected(peripheral:CBPeripheral){
        print("memePeripheralConnected \(peripheral)")
        
        //接続時は初期値にリセットする
        reset()
        
        //接続成功した MEMEを設定する
        currentPeripheral = peripheral

        if viewMemeDelegate != nil {
            viewMemeDelegate?.memePeripheralConnected(peripheral)
        }
    }
    
    /** JINS MEMEとの切断を受け取る
    *
    * @param peripheral 切断されたJINS MEME
    *
    */
    @objc func memePeripheralDisconneted(peripheral:CBPeripheral){
        print("memePeripheralDisconneted \(peripheral)")
        //切断したので 初期化
        currentPeripheral = nil

        
        if viewMemeDelegate != nil {
            viewMemeDelegate?.memePeripheralDisconneted(peripheral)
        }
    }
    
    /** MEME リアルタイムモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    @objc func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!, currentHeading:CLHeading!){
        //歩くスピードで SE を変更したりする
        //print("memeRealTimeModeDataReceived \(data)")
        
        doWalking(data,currentLocation: currentLocation, currentHeading:currentHeading)
        
        
        if viewMemeDelegate != nil {
            viewMemeDelegate?.memeRealTimeModeDataReceived(data, currentLocation:currentLocation, currentHeading:currentHeading)
        }
    }
    
    
    /** 歩行中の処理
    *
    * @param data MEMEから取得したリアルタイムデータ
    *
    */
    func doWalking(data: MEMERealTimeData,currentLocation: CLLocation!, currentHeading:CLHeading!){
        //歩行中かのステータスを確認
        if data.isWalking != 1 {
            return
        }
        
        if currentCondition == .Walking {
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
        
        // currentCondition で 歩行中SEの変更
        switch currentCondition {
        case .Running:
            //走っている時
            SoundEffectUtil.play("running")
        case .BadPosture:
            //姿勢が悪い
            SoundEffectUtil.play("poison")
        case .LookingAround:
            //キョロキョロ
            SoundEffectUtil.play("looking_around")
        case .Speepy:
            //眠い時
            SoundEffectUtil.play("speepy")
        default:
            //通常の歩行
            SoundEffectUtil.play("walking")
        }
        
        //歩数を加算
        stepCount += 1
        
        //TODO: 歩数と時間等でLVを計算する
        let lv:Int = stepCount/10 + 1
        
        //ログを作成
        let log = ArukuSurroundWalkLog()
        log.uuid = saveLogUuid;
        log.latitude  = currentLocation.coordinate.latitude
        log.longitude = currentLocation.coordinate.longitude
        log.walkStatus = currentCondition.hashValue
        log.stepCount = stepCount
        log.lv = lv
        log.powerLeft = data.powerLeft
        
        //CEATEC向けに 位置情報を偽装する
        if ArukuSurroundUtil.MODE_DEMO == true {
            demo_move(log,currentLocation:currentLocation,currentHeading:currentHeading)
        }
        
        //非同期で周辺イベントを取得する
        ArukuSurroundUtil.dispatch_async_main { () -> () in
            
            //イベント一を取得
            ArukuSurroundUtil.loadMapEvent(log.latitude, longitude:log.longitude, withinKilometers: Config.MAP_EVENT_WITH_IN_KILOMETERS, callback: { (data, error) -> Void in
                
                if error == nil && data != nil && data!.count > 0 {
                    //イベントが会ったことをデリゲートに通知
                    if self.viewMemeDelegate != nil {
                        self.viewMemeDelegate.doMapEvent(data!)
                    }
                }
            })
        }
        
        //非同期でログ保存を実行する
        ArukuSurroundUtil.dispatch_async_main { () -> () in
            
            //ログをサーバに送信して保存
            ArukuSurroundUtil.saveWalkLog(log)
        }
        
        //デリゲートに通知
        if self.viewMemeDelegate != nil {
            self.viewMemeDelegate.doWalking(log)
        }
        
        //音の処理をしたので 初期値に戻す
        self.currentCondition = .Walking

    }
    
    //DEMO用移動
    func demo_move(log:ArukuSurroundWalkLog, currentLocation: CLLocation!, currentHeading:CLHeading!){
        // 参考 https://gist.github.com/naoty/5821666
        
        //初回だけ位置情報を設定
        if demoCurrentLocation == nil {
            demoCurrentLocation = currentLocation.coordinate
        }
        
        //地球の半径
        let EARTH_RADIUS:Double = 6378150
        
        //緯線上の移動距離
        let latitude_distance = Config.DEMO_STEP_SIZE_METRE * cos(currentHeading.magneticHeading*M_PI/180)
        
        //1mあたりの緯度
        let earth_circle = 2 * M_PI * EARTH_RADIUS
        let latitude_per_meter = 360 / earth_circle
        
        //緯度の変化量
        let latitude_delta = latitude_distance * latitude_per_meter
        let new_latitude = demoCurrentLocation.latitude + latitude_delta
        
        //経線上の移動距離
        let longitude_distance = Config.DEMO_STEP_SIZE_METRE * sin(currentHeading.magneticHeading * M_PI / 180)
        
        //1mあたりの経度
        let earth_radius_at_longitude = EARTH_RADIUS * cos(new_latitude * M_PI / 180)
        let earth_circle_at_longitude = 2 * M_PI * earth_radius_at_longitude
        let longitude_per_meter = 360 / earth_circle_at_longitude
        
        //経度の変化量
        let longitude_delta = longitude_distance * longitude_per_meter
        let new_longitude = demoCurrentLocation.longitude + longitude_delta
        
        //print("new latitude:\(new_latitude) longitude:\(new_longitude)")
        
        //デモ用の位置情報を更新
        demoCurrentLocation.latitude  = new_latitude
        demoCurrentLocation.longitude = new_longitude
        
        //移動後の距離をログに設定
        log.latitude  = new_latitude
        log.longitude = new_longitude
    }
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    @objc func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!, currentHeading:CLHeading!){
        //print("memeStandardModeDataReceived \(data)")
        
        //眠気のステータスを確認
        if data.sleepy  == MEME_FCS_A_LITTLE || data.sleepy  == MEME_FCS_VERY {
            //MEME_FCS_A_LITTLE: 少し眠い
            //MEME_FCS_VERY : 大変眠い
            currentCondition = .Speepy
        }
        
        if viewMemeDelegate != nil {
            viewMemeDelegate?.memeStandardModeDataReceived(data, currentLocation:currentLocation, currentHeading:currentHeading)
        }
        
    }
}

/** ArukuSurround MEMEController デリゲート
*
*/
protocol ArukuSurroundMEMEControllerDelegate {
    
    /** スキャン結果受信デリゲート
    *
    * @param peripheral スキャンされたJINS MEME
    *
    */
    func memePeripheralFound(peripheral: CBPeripheral!)
    
    
    /** JINS MEMEへの接続完了
    *
    * @param peripheral 接続されたJINS MEME
    *
    */
    func memePeripheralConnected(peripheral:CBPeripheral)
    
    /** JINS MEMEとの切断を受け取る
    *
    * @param peripheral 切断されたJINS MEME
    *
    */
    func memePeripheralDisconneted(peripheral:CBPeripheral)
    
    
    /** MEME リアルタイムモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!, currentHeading:CLHeading!)
    
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!, currentHeading:CLHeading!)
    
    /** 歩行ログの通知
    *
    * @param log MEMEから取得したデータを元に作成したログ
    *
    */
    func doWalking(log:ArukuSurroundWalkLog)
    
    /** 現在位置にマップイベントが登録されてる事を通知
    * @param event DBから取得したイベント一覧
    */
    func doMapEvent(events:[ArukuSurroundMapEvent])
}
