//
//  ArukuSurroundSetting.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/22.
//  Copyright © 2015年 古川信行. All rights reserved.
/** 各設定値
*
*/
import Foundation

class ArukuSurroundSetting {
    
    //ユーザー
    var user:NCMBUser!
    
    //BOCCO room_id
    var bocco_room_id:String?
    
    //BOCCO ユーザーアクセストークン
    var bocco_access_token:String?
    
    //JINS MEMEの識別子
    var jins_meme_device_uuid:String?
    
    //イニシャライザ
    init(){
        
    }
    
    //イニシャライザ
    init(object:NCMBObject){
        user = object.objectForKey("user") as! NCMBUser
        bocco_room_id = object.objectForKey("boccoRoomId") as? String
        bocco_access_token = object.objectForKey("boccoAccessToken") as? String
        jins_meme_device_uuid = object.objectForKey("jinsMemeDeviceUuid") as? String
    }
}