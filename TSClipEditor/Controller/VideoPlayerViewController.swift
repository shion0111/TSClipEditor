//
//  VideoPlayerViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 05/07/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa
class MyVideoView : NSView{//VLCVideoView{
    
}
class VideoPlayerViewController: NSViewController{//,VLCMediaPlayerDelegate {
    
    var vidInfo:VideoInfoProtocol?
    var start: Float = 0
    var end: Float = 0
    var vidpath : String!
    //var videoView: VLCVideoView! = nil
    @IBOutlet weak var videoHolderView: NSView!
    @IBOutlet weak var playBtn : NSButton!
    @IBOutlet weak var timeLabel : NSTextField!
    
    //var player : VLCMediaPlayer! = nil //VLCMediaPlayer()
    
    deinit {
//        player.stop()
//        player.delegate = nil
        
    }
    /*
    override func viewWillAppear() {
        videoView.setFrameSize(NSMakeSize(480, 270))
        if !player.isPlaying {
            playPause(self.playBtn)
        }
    }
 */
    func delay(_ delay: Double, closure: @escaping() -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
        
    }
    func cleanup() {
//        if (self.videoView != nil) {//} && (self.videoView.hasVideo) {
//            if self.player.isPlaying {
//                self.playPause(self.playBtn)
//            }
//            self.player.stop()
//            videoView.removeFromSuperview()
//            videoView = nil
//            player.delegate = nil
//            player = nil
//            self.timeLabel.stringValue = "00:00:00"
//        }
    }
    func prepareVideo(start: Float, end:Float, path:String){
        
        cleanup()
        
        var rect = NSMakeRect(0, 0, 0, 0);
        rect.size = self.videoHolderView.frame.size;
        
        //videoView = VLCVideoView(frame: rect)//[[VLCVideoView alloc] initWithFrame:rect];
        
        
        //videoView.fillScreen = true
        
        
        self.start = start
        self.end = end
        self.vidpath = path
        
        
//        self.player = VLCMediaPlayer(videoView: self.videoView)
//        //player.setVideoView(videoView)
//        self.player.drawable = videoView
//        self.player.media = VLCMedia(path: self.vidpath)
//        self.player.delegate = self
//        self.videoHolderView.addSubview(self.videoView)
//
//        if !self.player.isPlaying {
//            self.playPause(self.playBtn)
//            self.videoView.frame = CGRect(x: 0, y: 0, width: rect.width*2, height: rect.height*2)
//        }
//
//        //  MARK: - VLCKit has a resizing issue on OS X https://code.videolan.org/videolan/VLCKit/issues/82
//        //  Workaround: try to resize the videoView twice to enforce VoutDisplayEvent 'resize' invoked
//        //  but mostly at first launch this workaround doesn't work......
//        delay(0.5) {
//            self.videoView.frame = rect
//        }
//
//        //  MARK: - jumpto the start
//        delay(0.5){
//            self.player.jumpForward(Int32(start))
//        }
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func collapseViewer(_ sender:AnyObject) {
        
//        if ((player != nil) && player.isPlaying) {
//            player.pause()
//        }
//
//        vidInfo?.collapseClipViewController()
    }
    
    @IBAction func playPause(_ sender:AnyObject){
//        print(self.player.state.rawValue)
//        if player.isPlaying {
//            player.pause()
//            playBtn.title = "Play"
//
//        } else {
//            player.play()
//            playBtn.title = "Pause"
//            if start != 0 {
//                //let newTime: VLCTime = VLCTime(int: Int32(start))
//                //self.player.jumpForward(Int32(start))//time = newTime
//
////                self.player.time = VLCTime(int:self.player.time.intValue + Int32(start*1000))
//                start = 0
//            }
//        }
    }
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
//        self.timeLabel.stringValue = player.time.stringValue;
    }
    /*
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        
        switch self.player.state.rawValue {
            
        case 2:
            bufferingcount = bufferingcount+1
            print("bufferingcount :\(bufferingcount)");
            
            break
        case 1:
            
            break
        default:
            print(self.player.state)
        }
        
        print("*** \(self.player.state.rawValue)\n\n")
    }
    */
    
}
