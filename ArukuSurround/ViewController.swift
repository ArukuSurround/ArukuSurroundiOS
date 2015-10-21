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
        ArukuSurroundUtil.isLogin({ (user) -> Void in
            if user != nil {
                //ログイン中なのでメイン画面へ遷移する
                self.performSegueWithIdentifier("segueShowMain",sender: nil)
            }
            else{
                //ログインしてなかった場合
                print("未ログイン")
            }
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        
        //MEMEとの接続を切断
        ArukuSurroundUtil.memeDisconnect()
        
        //進捗ダイアログを非表示に
        SVProgressHUD.dismiss()
    }
    
    /** Twitterでログイン
    *
    */
    @IBAction func clickBtnLoginTwitter(sender: AnyObject) {
        SVProgressHUD.showWithStatus("ログイン中...")
        
        //Twitterでログインする
        ArukuSurroundUtil.loginTwitter({ (user, error) -> Void in
            //進捗ダイアログを非表示に
            ArukuSurroundUtil.dispatch_async_main { () -> () in
                SVProgressHUD.dismiss()
            }
            
            if user != nil {
                print("ログイン成功 user:\(user)")
                
                //ドア音 再生
                SoundEffectUtil.play("door")
                
                //メイン画面へ遷移する
                self.performSegueWithIdentifier("segueShowMain",sender: nil)
            }
            else{
                print("ログイン失敗 error:\(error)")
                
                //呪い音再生
                SoundEffectUtil.play("curse")
                
                //アラートを表示する
                ArukuSurroundUtil.showAlert(self, title:"失敗", message: "ログインに失敗しました。", btnTitle: "OK", callback: { () -> Void in
                     print("OK")
                })
            }
        })
    }
}

