//
//  VideoPlayerViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 05/07/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa

class VideoPlayerViewController: NSViewController,VLCMediaPlayerDelegate {

    var start: Float = 0
    var end: Float = 0
    var vidpath : String!
    @IBOutlet weak var videoView: VLCVideoView!
    @IBOutlet weak var playBtn : NSButton!
    var player : VLCMediaPlayer = VLCMediaPlayer()
    
    deinit {
        player.stop()
        player.delegate = nil
        
    }
    override func viewWillAppear() {
        if !player.isPlaying {
            playPause(self.playBtn)
        }
    }
    func prepareVideo(start: Float, end:Float, path:String){
        
        videoView.frame = NSMakeRect(0,50,480,270)
        videoView.autoresizingMask = [.width,.height]
        videoView.fillScreen = true
        
        self.start = start
        self.end = end
        self.vidpath = path
        
        
        //self.player = VLCMediaPlayer(videoView: self.videoView)
        player.setVideoView(videoView)
        self.player.drawable = videoView
        self.player.media = VLCMedia(path: self.vidpath)
        self.player.delegate = self
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func playPause(_ sender:AnyObject){
        print(self.player.state.rawValue)
        if player.isPlaying {
            player.pause()
            playBtn.title = "Play"
        } else {
            player.play()
            playBtn.title = "Pause"
        }
    }
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
    }
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        switch self.player.state.rawValue {
        case 2:
            if start != 0 {
                //self.player.position = 0.5
                self.player.jumpForward(Int32(start))
                start = 0
            }
            break
        case 1:
            
            break
        default:
            print(self.player.state)
        }
        print("*** \(self.player.state.rawValue)\n\n")
    }
    
    
}
