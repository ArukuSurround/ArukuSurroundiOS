//
//  SettingViewController.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/24.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import UIKit

/** 設定画面のビューコントローラー
*
*/
class SettingViewController: UIViewController {
    
    //BOCCOのルームID
    @IBOutlet weak var txtBoccoRoomId: UITextField!

    //BOCCOのアクセストークン
    @IBOutlet weak var txtBoccoAccessToken: UITextField!
    
    //JINS MEMEのUUID
    @IBOutlet weak var txtJinsMemeDeviceUUID: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ロード済みの設定を画面に設定する
        if ArukuSurroundUtil.setting != nil {
            txtBoccoRoomId.text = ArukuSurroundUtil.setting.bocco_room_id
            txtBoccoAccessToken.text = ArukuSurroundUtil.setting.bocco_access_token
            txtJinsMemeDeviceUUID.text = ArukuSurroundUtil.setting.jins_meme_device_uuid
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** 閉じるボタン
    */
    @IBAction func clickBtnClose(sender: AnyObject) {
        //必須項目の入力値のチェックをする
        if txtBoccoRoomId.text == "" {
            //空白は入力できないので元に戻す
            ArukuSurroundUtil.showAlert(self, title:"入力値の確認", message: "BOCCO room idは必須項目です。入力値を確認してください", btnTitle: "OK", callback: { () -> Void in
                self.txtBoccoRoomId.text = ArukuSurroundUtil.setting.bocco_room_id
            })
            return
        }
        if txtBoccoAccessToken.text == "" {
            //空白は入力できないので元に戻す
            ArukuSurroundUtil.showAlert(self, title:"入力値の確認", message: "BOCCOのAccess_Token は必須項目です。入力値を確認してください", btnTitle: "OK", callback: { () -> Void in
                self.txtBoccoAccessToken.text = ArukuSurroundUtil.setting.bocco_room_id
            })
            return
        }
        
        if ArukuSurroundUtil.setting == nil {
            ArukuSurroundUtil.setting = ArukuSurroundSetting()
        }
        
        //ここで保存されている値に変更がある場合 更新していいか確認する
        if txtBoccoRoomId.text != ArukuSurroundUtil.setting.bocco_room_id
            || txtBoccoAccessToken.text != ArukuSurroundUtil.setting.bocco_access_token
            || txtJinsMemeDeviceUUID.text != ArukuSurroundUtil.setting.jins_meme_device_uuid {
                
                //更新していいか確認する
                ArukuSurroundUtil.showConfirm(self, title:"確認", message: "入力値が変更されています。保存してもよろしいですか？",
                    btnCancelTitle: "キャンセル", cancelCallback: { () -> Void in
                        print("キャンセル")
                    },
                    btnOkTitle: "OK", okCallback: { () -> Void in
                        //保存処理を実行する
                        self.updateSetting({ (error) -> Void in
                            //保存 結果
                            if error == nil {
                                //画面を閉じる
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                            else{
                            ArukuSurroundUtil.showAlert(self,
                                title: "エラー",
                                message: "保存に失敗しました。",
                                btnTitle: "OK",
                                callback: { () -> Void in
                                    print("OK")
                                })
                            }
                            
                        })
                })
                
        }
        else{
            //値に変更がなかった場合
            //画面を閉じる
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /** 設定値を更新して保存
    */
    func updateSetting(callback:((error:NSError?)->Void)){
        ArukuSurroundUtil.setting.bocco_room_id = txtBoccoRoomId.text
        ArukuSurroundUtil.setting.bocco_access_token = txtBoccoAccessToken.text
        ArukuSurroundUtil.setting.jins_meme_device_uuid = txtJinsMemeDeviceUUID.text
        
        //保存
        ArukuSurroundUtil.saveSetting(ArukuSurroundUtil.setting, callback:{ (error) -> Void in
            callback(error:error)
        })
    }
    
    /** ダミー設定を設定する
    */
    @IBAction func clickBtnLoadDummy(sender: AnyObject) {
        txtBoccoRoomId.text = "f5020da2-f2ec-4d11-a1f9-7a21463a88ba"
        txtBoccoAccessToken.text = "a3d24268891402706e765d128c647429bd922099a2000d79a68a1fec5406cc45"
        txtJinsMemeDeviceUUID.text = "0D60FD88-D04B-C95F-B14B-4B2BA6FE88D4eee"
    }
}