//
//  SoundEffectUtil.swift
//  ArukuSurround
//
//  Created by 古川信行 on 2015/09/22.
//  Copyright © 2015年 古川信行. All rights reserved.
//

import Foundation
import AVFoundation

class SoundEffectUtil {
    
    //SE再生用のオーディオプレイヤー
    static var audioPlayer:AVAudioPlayer! = nil
    
    /** オーディオセッションを初期化
    *
    */
    static func initAudioSession(){
        //オーディオセッションの初期設定を変更
        do {
            let audioSession = AVAudioSession.sharedInstance()
        
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        }
        catch {
            print("initAudioSession error")
        }
    }
    
    /** SE再生,停止
    *
    * @param file_name 再生したいファイル名
    *
    */
    static func play(file_name:String){
        if audioPlayer != nil && audioPlayer.playing == true {
            audioPlayer.stop()
        }
        
        do{
            let sound_data = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(file_name, ofType: "mp3")!)
            try audioPlayer = AVAudioPlayer(contentsOfURL: sound_data, fileTypeHint: nil)
            audioPlayer.play()
        }
        catch {
            print("play error")
        }
    }
}