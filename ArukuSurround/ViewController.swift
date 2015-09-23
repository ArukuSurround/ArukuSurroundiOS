//
//  ViewController.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/18.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //ログイン 状態を確認
        ArukuSurroundUtil.isLogin { (user) -> Void in
            if user != nil {
                //ログイン中
                //TODO: ログイン済みの画面へ遷移
                print("ログイン中 user:\(user)")
            }
            else{
                //ログインしてなかった場合
                print("未ログイン")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /** Twitterでログイン
    *
    */
    @IBAction func clickBtnLoginTwitter(sender: AnyObject) {
        //Twitterでログインする
        ArukuSurroundUtil.loginTwitter({ (user, error) -> Void in
            
            if user != nil {
                print("ログイン成功 user:\(user)")
            }
            else{
                print("ログイン失敗 error:\(error)")
            }
        })
    }

    /** 匿名ユーザーを削除する
    *
    */
    @IBAction func clickBtnDeleteAnonymousUser(sender: AnyObject) {
        //匿名ユーザーを削除する
        ArukuSurroundUtil.deleteAnonymousUser()
    }
    
    /** 設定値を保存する
    *
    */
    @IBAction func clickBtnSaveSetting(sender: AnyObject) {
        //仮でココでパラメタを埋めてみる
        let setting = ArukuSurroundSetting()
        setting.bocco_room_id = "f5020da2-f2ec-4d11-a1f9-7a21463a88ba"
        setting.bocco_access_token = "a3d24268891402706e765d128c647429bd922099a2000d79a68a1fec5406cc45"
        setting.jins_meme_device_uuid = "0D60FD88-D04B-C95F-B14B-4B2BA6FE88D4eee"
        
        //保存
        ArukuSurroundUtil.saveSetting(setting)
    }
    
    /** 歩く事を開始
    *
    */
    @IBAction func clickBtnStartWalk(sender: AnyObject) {
        ArukuSurroundUtil.startWalk()
    }
    
    /** 歩く事を停止
    *
    */
    @IBAction func clickBtnEndWalk(sender: AnyObject) {
        ArukuSurroundUtil.endWalk()
    }
}

