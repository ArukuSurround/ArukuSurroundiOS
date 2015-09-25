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

    /** Twitterでログイン
    *
    */
    @IBAction func clickBtnLoginTwitter(sender: AnyObject) {
        //Twitterでログインする
        ArukuSurroundUtil.loginTwitter({ (user, error) -> Void in
            
            if user != nil {
                print("ログイン成功 user:\(user)")
                //メイン画面へ遷移する
                self.performSegueWithIdentifier("segueShowMain",sender: nil)
            }
            else{
                print("ログイン失敗 error:\(error)")
                //アラートを表示する
                ArukuSurroundUtil.showAlert(self, title:"失敗", message: "ログインに失敗しました。", btnTitle: "OK", callback: { () -> Void in
                     print("OK")
                })
            }
        })
    }
}

