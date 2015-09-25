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
    enum Condition {
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
    
    /** 各カウンターをリセットする
    *
    */
    func reset(){
        stepCount = 0
        lookingAroundCount = 0
        badPostureCount = 0
        runningCount = 0
        
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
            if peripheral.identifier.UUIDString == setting.jins_meme_device_uuid {
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
    @objc func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!){
        //歩くスピードで SE を変更したりする
        //print("memeRealTimeModeDataReceived \(data)")
        
        doWalking(data,currentLocation: currentLocation)
        
        
        if viewMemeDelegate != nil {
            viewMemeDelegate?.memeRealTimeModeDataReceived(data, currentLocation: currentLocation)
        }
    }
    
    
    /** 歩行中の処理
    *
    * @param data MEMEから取得したリアルタイムデータ
    *
    */
    func doWalking(data: MEMERealTimeData,currentLocation: CLLocation!){
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
        let lv:Int = stepCount/10
        
        //ログを作成
        let log = ArukuSurroundWalkLog()
        log.uuid = saveLogUuid;
        log.latitude  = currentLocation.coordinate.latitude
        log.longitude = currentLocation.coordinate.longitude
        log.walkStatus = currentCondition.hashValue
        log.stepCount = stepCount
        log.lv = lv
        log.powerLeft = data.powerLeft
        
        //ログをサーバに送信して保存
        ArukuSurroundUtil.saveWalkLog(log)
        
        //デリゲートに通知
        if viewMemeDelegate != nil {
            viewMemeDelegate.doWalking(log)
        }
        
        //音の処理をしたので 初期値に戻す
        currentCondition = .Walking
    }
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    @objc func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!){
        //print("memeStandardModeDataReceived \(data)")
        
        //眠気のステータスを確認
        if data.sleepy  == MEME_FCS_A_LITTLE || data.sleepy  == MEME_FCS_VERY {
            //MEME_FCS_A_LITTLE: 少し眠い
            //MEME_FCS_VERY : 大変眠い
            currentCondition = .Speepy
        }
        
        if viewMemeDelegate != nil {
            viewMemeDelegate?.memeStandardModeDataReceived(data, currentLocation: currentLocation)
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
    func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!)
    
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!)
    
    /** 歩行ログの通知
    *
    * @param log MEMEから取得したデータを元に作成したログ
    *
    */
   func doWalking(log:ArukuSurroundWalkLog)
}
