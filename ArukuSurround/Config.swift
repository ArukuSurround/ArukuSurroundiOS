//
//  Config.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/18.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import Foundation

/** 初期設定等を記載するクラス
*
*/
public class Config {

    //nifty mBaaS アプリケーションキー
    public static var NCMB_APPLICATION_KEY:String = "e12816d85731c50af473e5580380ac195aebd070ad8e1c330979f1b7d152db68"
    
    //nifty mBaaS クライアントキー
    public static var NCMB_CLIENT_KEY:String = "e5f532f3bd87db183da303248e9ddcf652f847b19f2fcb837acaa5082a9b825d"
    
    //nifty mBaaS 公開ファイル取得API
    public static var NCMB_PBLIC_FILE_API_HOST = "https://mb.api.cloud.nifty.com/2013-09-01/applications/TC6ruxnBKRRj69gW/publicFiles"
    
    //Twitter連動 Consumer Key
    public static var TWITTER_API_KEY:String = "cOSab8VvEkifRFiDgb1EyzykA"
    
    //Twitter連動 Secret Key
    public static var TWITTER_API_SECRET:String = "yUSW6yFkyVi2DOxo4SXJZEqKlEa6s3dVHXVmxEbmbKMRSu5raV"
    
    //JINS MEME APP ID
    public static let MEME_APP_ID:String = "086730792787486"
    
    //JINS MEME APP SECRET
    public static let MEME_APP_SECRET:String = "v5iqgzt4cj7sb8e6o0yoah0jxsduh76j"
    
    //SAVE メッセージ パターン
    public static let SAVE_MESSAGES:[String:String] = ["BAD":"{STEP_COUNT}歩 とは情けない...。",
                                                       "DEFAULT":"{STEP_COUNT}歩 でした。次回もがんばって!",
                                                       "PRAISE":"{STEP_COUNT}歩 でした。沢山歩いて凄いです！",
                                                       "RUNNING":"急いでどこかへお出かけですか？。事故には気をつけて。",
                                                       "LOOKING_AROUND":"キョロキョロしすぎだったようです。気をつけて。",
                                                       "BAD_POSTURE":"下を向いて歩くと気分が滅入りますよ...元気だしてください。",
                                                       "SLEEP":"お疲れのようですね...。休む事も大切ですよ!"]
}