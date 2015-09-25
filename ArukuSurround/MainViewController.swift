//
//  MainViewController.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/24.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import UIKit

/** メイン画面のビューコントローラー
*/
class MainViewController: UIViewController,ArukuSurroundMEMEControllerDelegate {
    
    //BOCCOのアイコン
    @IBOutlet weak var imgViewBocco: UIImageView!
    
    //ステータス テキスト エリア
    @IBOutlet weak var txtStatus: UITextView!
    
    //MAP表示の為の WebView
    @IBOutlet var viewWebMap: UIWebView!
    
    //開始ボタン
    @IBOutlet weak var btnStart: UIButton!
    
    //最後の歩行ログ
    var currentWalkingLog:ArukuSurroundWalkLog!
    
    //設定ボタン
    //var btnSetting: UIBarButtonItem!
    
    //歩きアニメーションの為の値
    enum Step {
        case Stop
        case Left
        case Right
    }
    var boccoStep:Step = .Stop
    
    //ステータス異常 眠気
    let conditionSpeepy = ArukuSurroundUtilMEMEDelegate.Condition.Speepy.hashValue
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定ボタンを設置
        //btnSetting = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "clickBtnSetting")
        //self.navigationItem.rightBarButtonItem = btnSetting
        
        //ステータス テキストを初期化
        txtStatus.text = createStatusText(nil)
        
        // 初期設定が終わっているか確認する        
        if ArukuSurroundUtil.setting != nil {
            // 初期設定画終わっていない場合は設定画面へ遷移
            if ArukuSurroundUtil.setting?.bocco_room_id == nil || ArukuSurroundUtil.setting?.bocco_access_token == nil {
                //未設定なので設定画面へ遷移
                self.clickBtnSetting(nil)
            }
        }
        else{
            print("error");
            //何らかのエラーなのでアラートを表示する
            ArukuSurroundUtil.showAlert(self, title:"エラー", message: "設定の読み込みに失敗しました。設定を確認してください。", btnTitle: "OK", callback: { () -> Void in
                print("OK")
                
                //未設定なので設定画面へ遷移
                self.clickBtnSetting(nil)
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //背景にMAPを表示する
        let request = NSURLRequest(URL: NSURL(string: "\(Config.NCMB_PBLIC_FILE_API_HOST)/index.html")!)
        self.viewWebMap.loadRequest(request)
        self.view.sendSubviewToBack(self.viewWebMap)
    }

    /** 設定ボタンが押された時
    *
    */
    @IBAction func clickBtnSetting(sender: AnyObject?){
        //設定 画面へ遷移する
        let vc:UIViewController  = self.storyboard!.instantiateViewControllerWithIdentifier("viewSetting")
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    /** 歩く事を開始
    *
    */
    @IBAction func clickBtnStartWalk(sender: AnyObject) {
        //ステータス表示を初期化
        txtStatus.text = createStatusText(nil)
        
        ArukuSurroundUtil.startWalk( self )
        
        //STARTボタンを 非表示にする
        btnStart.hidden = true
    }
    
    /** 歩く事を停止&保存
    *
    */
    @IBAction func clickBtnEndWalk(sender: AnyObject) {
        ArukuSurroundUtil.endWalk()
        
        //STARTボタンを 表示
        btnStart.hidden = false
    }
    
    // MARK: - ArukuSurroundMEMEControllerDelegate
    
    /** スキャン結果受信デリゲート
    *
    * @param peripheral スキャンされたJINS MEME
    *
    */
    func memePeripheralFound(peripheral: CBPeripheral!){
    
    }
    
    
    /** JINS MEMEへの接続完了
    *
    * @param peripheral 接続されたJINS MEME
    *
    */
    func memePeripheralConnected(peripheral:CBPeripheral){
        //接続成功したので メガネ付きの BOCCO にアイコンを変更
        imgViewBocco.image = UIImage(named:"paring_bocco_paird")
    }
    
    /** JINS MEMEとの切断を受け取る
    *
    * @param peripheral 切断されたJINS MEME
    *
    */
    func memePeripheralDisconneted(peripheral:CBPeripheral){
        //切断されたので 赤目のBOCCOにする
        imgViewBocco.image = UIImage(named:"bocco_red_stop")
        
        //STARTボタンを 表示
        btnStart.hidden = false
    }
    
    
    /** 歩行ログの通知
    *
    * @param log MEMEから取得したデータを元に作成したログ
    *
    */
    func doWalking(log:ArukuSurroundWalkLog){
        //ステータス テキストを初期化
        txtStatus.text = createStatusText(log)
        txtStatus.textColor = UIColor.whiteColor()
        
        //眠気が会った場合
        if log.walkStatus == conditionSpeepy {
            //テキストの色を 橙に変更
            txtStatus.textColor = UIColor.orangeColor()
        }
        
        currentWalkingLog = log
    }
    
    /** 表示用のテキストを生成する
    */
    func createStatusText(log:ArukuSurroundWalkLog?) -> String {
        var lv:Int = 1
        var hp:Int = 100
        let maxHp:Int = 100
        var status:String = "けんこう"
        var stepCount:Int = 0
        
        if log != nil {
            lv = log!.lv
            hp = (log!.powerLeft.hashValue/5)*maxHp
            if log!.walkStatus == conditionSpeepy {
                status = "ねむい"
            }
            stepCount = log!.stepCount
        }
        
        let result:String = "ＬＶ: \(lv)\n"
                            + "ＨＰ: \(hp)/\(maxHp)\n"
                            + "じょうたい: \(status)\n"
                            + "そうほすう: \(stepCount)ほ"
        
        return result
    }
    
    /** MEME リアルタイムモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!){
        
        //歩行中かのステータス確認
        if data.isWalking != 1 {
            //停止している時
            //boccoStep = .Stop
        }
        else{
            //歩行中
            if boccoStep != .Left {
                boccoStep = .Left
            }
            else{
                boccoStep = .Right
            }
        }
        
        //ログ未設定なら以下の処理はしない
        if currentWalkingLog == nil {
            imgViewBocco.image = UIImage(named: "bocco_stop")
            return
        }
        
        //BOCCO アイコンの切り替え
        var iconName:String = "bocco_stop"
        
        switch boccoStep{
        case .Stop:
            iconName = "bocco_stop"
        case .Left:
            iconName = "bocco_left"
        case .Right:
            iconName = "bocco_right"
        }
        
        //瞬きに対応
        if data.blinkSpeed > 0{
            if let r = iconName.rangeOfString("_red") {
                //そのまま
            }
            else{
                //赤目にする
                iconName = iconName + "_red"
            }
        }
        
        imgViewBocco.image = UIImage(named: iconName)
    }
    
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!){
    
    }
}
