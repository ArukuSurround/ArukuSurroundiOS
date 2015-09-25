//
//  MEMEController.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/19.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import Foundation
import CoreLocation

class MEMEController:NSObject, MEMELibDelegate, CLLocationManagerDelegate {

    //デリゲート
    var delegate:MEMEControllerDelegate! = nil
    
    //MEMEのデータ取得モード変更タイマー
    var timerChangeDataMode:NSTimer?
    
    //ロケーションマネージャ
    var locationManager = CLLocationManager()
    
    //最後に更新された位置情報
    var currentLocation: CLLocation?
    
    /** イニシャライザ
    *
    */
    override init(){
        super.init()
        
        //JINS MEME の 初期化
        MEMELib.setAppClientId(Config.MEME_APP_ID, clientSecret: Config.MEME_APP_SECRET)
        
        //MEMELibのデリゲートを設定
        MEMELib.sharedInstance().delegate = self
        
        //MEMELibをリアルタイムモードに設定
        MEMELib.sharedInstance().changeDataMode(MEME_COM_REALTIME)
        
        //位置情報取得の為の初期化
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        locationManager.delegate = self
    }
    
    /** メインスレッドで実行する
    *
    * @param block メインスレッドで実行する処理
    *
    */
    static func dispatch_async_main(block: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    /** MEME検索を開始する
    *
    */
    func startScanningMeme(){
        //print("startScanningMeme \(MEMELib.sharedInstance())")
        MEMELib.sharedInstance().startScanningPeripherals()
    }
    
    /** 位置情報取得を開始する
    *
    */
    func startUpdatingLocation(){
        let status:CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        //print("startUpdatingLocation status:\(status.hashValue)")
        switch status{
        case .NotDetermined:
            if locationManager.respondsToSelector("requestWhenInUseAuthorization"){
                locationManager.requestWhenInUseAuthorization()
            }else{
                locationManager.startUpdatingLocation()
            }
            break
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            locationManager.startUpdatingLocation()
            break
        case .Restricted, .Denied:
            break
        //default:
        //    break
        }
    }
    
    /** 指定のMEMEに接続する
    *
    * @param peripheral 接続対象のJINS MEME
    */
    static func connectPeripheral(peripheral: CBPeripheral!){
        MEMELib.sharedInstance().connectPeripheral(peripheral)
    }
    
    
    /** 接続中のMEMEから切断する
    *
    */
    static func disconnectPeripheral(){
        MEMELib.sharedInstance().disconnectPeripheral()
    }
    
    /** MEMEの取得モードを切り替え
    *
    */
    func fetchStandardData(timer:NSTimer){
        MEMELib.sharedInstance().changeDataMode(MEME_COM_STANDARD)
    }
    
    // MARK: - MEMELibDelegate

    /** 認証結果
    *
    * @param memeStatus 認証結果
    *
    */
    @objc func memeAppAuthorized(memeStatus: MEMEStatus) {
        //print("memeAppAuthorized \(memeStatus)")
    }
    
    /** スキャン結果受信
    *
    * @param peripheral スキャンして見つけたJINS MEME
    *
    */
    @objc func memePeripheralFound(peripheral: CBPeripheral!) {
        //print("peripheral found \(peripheral.identifier.UUIDString)")
        
        if delegate != nil {
            delegate?.memePeripheralFound(peripheral)
        }
    }
    
    /** JINS MEMEへの接続完了
    *
    * @param peripheral 接続されたJINS MEME
    *
    */
    @objc func memePeripheralConnected(peripheral:CBPeripheral){
    
        //MEMEのモード切り替えタイマーを開始する
        if timerChangeDataMode == nil {
            timerChangeDataMode = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: Selector("fetchStandardData:"), userInfo: nil, repeats: false)
        }
                
        //MEMEが見つかったので位置情報取得も開始する
        MEMEController.dispatch_async_main { () -> () in
            self.startUpdatingLocation()
        }
        
        //デリゲートに通知
        if delegate != nil {
            delegate?.memePeripheralConnected( peripheral )
        }
    }
    
    /** JINS MEMEとの切断を受け取る
    *
    * @param peripheral 切断されたJINS MEME
    *
    */
    @objc func memePeripheralDisconneted(peripheral:CBPeripheral){
        //デリゲートに通知
        if delegate != nil {
            delegate?.memePeripheralDisconneted(peripheral)
        }
    }
    
    /** MEME リアルタイムモードのデータ受信
    *
    * @param data MEMEから取得したリアルタイムデータ
    *
    */
    @objc func memeRealTimeModeDataReceived(data: MEMERealTimeData) {
        if currentLocation == nil{
            print("currentLocation is nil")
            return
        }
        
        // 装着状態に異常あり
        if data.fitError != 0 {
            return
        }
        
        //デリゲートに通知
        if delegate != nil {
            delegate?.memeRealTimeModeDataReceived(data, currentLocation: currentLocation)
        }
    }
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    @objc func memeStandardModeDataReceived(data: MEMEStandardData) {
        if currentLocation == nil{
            print("currentLocation is nil")
            return
        }
        
        // 装着状態に異常あり
        if data.fitError != 0 {
            return
        }
        
        //デリゲートに通知
        if delegate != nil {
            delegate?.memeStandardModeDataReceived(data, currentLocation: currentLocation)
        }
        
        //MEMELibをリアルタイムモードに設定
        MEMELib.sharedInstance().changeDataMode(MEME_COM_REALTIME)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    /** ロケーション取得の許可ステータスの通知
    *
    * @param manager ロケーションマネージャー
    * @param status 位置情報取得 認証ステータス
    *
    */
    @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status{
            case .Restricted, .Denied:
                manager.stopUpdatingLocation()
            case .AuthorizedWhenInUse, .AuthorizedAlways:
                locationManager.startUpdatingLocation()
            default:
                break
        }
    }
    
    /** 位置情報の取得に成功した
    * @param manager ロケーションマネージャー
    * @param locations 取得できた位置情報一覧
    *
    */
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count <= 0{
            return;
        }
        
        //位置情報取得に成功
        currentLocation = locations[ locations.count-1 ]
    }
}

/** MEMEController デリゲート
*
*/
@objc protocol MEMEControllerDelegate {
    
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
}
