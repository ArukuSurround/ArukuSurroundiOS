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

    //デモボタン
    @IBOutlet weak var btnDemoStart: UIButton!
    
    //最後の歩行ログ
    var currentWalkingLog:ArukuSurroundWalkLog!
    
    //設定ボタン
    var btnSetting: UIBarButtonItem!
    
    //歩きアニメーションの為の値
    enum Step {
        case Stop
        case Left
        case Right
    }
    var boccoStep:Step = .Stop
    
    //ステータス異常 眠気
    let conditionSpeepy = ArukuSurroundUtilMEMEDelegate.Condition.Speepy.hashValue
    
    //MAPをロードしたか確認
    var isLoadMap:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定ボタンを設置
        btnSetting = UIBarButtonItem(title: "⚙", style: UIBarButtonItemStyle.Plain, target: self, action: "clickBtnSetting:")
        let font = UIFont(name: "PixelMplus12", size: 30)
        btnSetting.setTitleTextAttributes([NSFontAttributeName:font!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = btnSetting
        
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
        self.reloadMap( ArukuSurroundUtil.utilDelegate.saveLogUuid )
    }

    /** MAPをリロードする
    *
    */
    func reloadMap(uuid:String){
        let t = NSDate().timeIntervalSince1970
        let request = NSURLRequest(URL: NSURL(string: "\(Config.NCMB_PBLIC_FILE_API_HOST)/index.html?t=\(t)#\(uuid)")!)
        print("request:\(request)")
        
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
        //SVProgressHUD.showWithStatus("JINS MEMEを検索中...")
        
        //ステータス表示を初期化
        txtStatus.text = createStatusText(nil)
        
        //JINIS MEMEを検索して 歩行ログを記録開始
        ArukuSurroundUtil.startWalk( self, mode:false )
        
        //STARTボタンを 非表示にする
        btnStart.hidden = true
        btnDemoStart.hidden = true
    }
    
    /** デモモードで歩く事を開始
    *
    */
    @IBAction func clickBtnDemoStartWalk(sender: AnyObject) {
        //SVProgressHUD.showWithStatus("JINS MEMEを検索中...")
        
        //ステータス表示を初期化
        txtStatus.text = createStatusText(nil)
        
        //JINIS MEMEを検索して 歩行ログを記録開始 デモモードに設定
        ArukuSurroundUtil.startWalk( self, mode:true )
        
        //STARTボタンを 非表示にする
        btnStart.hidden = true
        btnDemoStart.hidden = true
    }
    
    /** 歩く事を停止&保存
    *
    */
    @IBAction func clickBtnEndWalk(sender: AnyObject) {
        SVProgressHUD.showWithStatus("保存中...")
        
        
        ArukuSurroundUtil.endWalk { () -> Void in
            
            ArukuSurroundUtil.dispatch_async_main { () -> () in
                SVProgressHUD.dismiss()
            }
            
            //STARTボタンを 表示
            self.btnStart.hidden = false
            self.btnDemoStart.hidden = false
            
            ArukuSurroundUtil.showAlert(self, title:"保存", message: "冒険を保存しました！", btnTitle: "OK", callback: { () -> Void in
                print("OK")
            })
        }
        
        
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
        SVProgressHUD.dismiss()
        
        //接続成功したので メガネ付きの BOCCO にアイコンを変更
        imgViewBocco.image = UIImage(named:"bocco_stop")
    }
    
    /** JINS MEMEとの切断を受け取る
    *
    * @param peripheral 切断されたJINS MEME
    *
    */
    func memePeripheralDisconneted(peripheral:CBPeripheral){
        //切断されたので 赤目のBOCCOにする
        imgViewBocco.image = UIImage(named:"bocco_normal_red")
        
        //STARTボタンを 表示
        btnStart.hidden = false
        btnDemoStart.hidden = false
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
        
        //バッテリー残量が 0 だった場合
        if log.powerLeft.hashValue == 0 {
            //テキストの色を 赤に変更
            txtStatus.textColor = UIColor.redColor()
        }
        //眠気が会った場合
        else if log.walkStatus == conditionSpeepy {
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
    func memeRealTimeModeDataReceived(data: MEMERealTimeData,currentLocation: CLLocation!, currentHeading:CLHeading!){
        
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
        
        if(self.isLoadMap == false){
            //初回だけMAPをロードする
            self.reloadMap( ArukuSurroundUtil.utilDelegate.saveLogUuid )
            self.isLoadMap = true
        }
        
        //コンパスに合わせて地図を回転させる
        //viewWebMap.stringByEvaluatingJavaScriptFromString("p.map_rotate(-\(currentHeading.magneticHeading))")        
    }
    
    
    /** MEME スタンダードモードのデータ受信
    *
    * @param data MEMEから取得したデータ
    *
    */
    func memeStandardModeDataReceived(data: MEMEStandardData,currentLocation: CLLocation!, currentHeading:CLHeading!){
    
    }
}
