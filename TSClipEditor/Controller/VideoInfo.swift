//
//  VideoInfo.swift
//  TSClipEditor
//
//  Created by Antelis on 2018/6/3.
//  Copyright © 2018 shion. All rights reserved.
//

import Foundation

typealias Duration = (start: Int, end: Int)

class ClipInfo :NSObject {
    var duration : Duration = Duration(start:0, end: 1)
    var index: Int = 0
    var isfocused: Bool = false
    var status : Int = 0
    
    func setDuration(_ s: Int, _ e: Int) {
        self.duration.start = s
        self.duration.end = e
    }
    
}
class VideoInfo: VideoInfoProtocol {

    private var clips : [ClipInfo] = []
    var progress: ProgressInfoProtocol?
    var tsduration : Int = 0
    var videopath: String = ""
    var thumbViewHandler: ((CGImage, Bool) -> ())?
    
    //  reset all properties
    func cleanUp() {
        clips.removeAll()
        tsduration = 0
        videopath = ""
        thumbViewHandler = nil
    }
    
    //  retrieve video duration/metadata via ffmpeg
    func loadVideoWithPath(path: String) -> (Int,Int) {
        
        cleanUp()
        videopath = path
        cleanVideoContext()
        self.tsduration = Int(getVideoDurationWithLoc(path))
        
        let st = 20
        return (Int(tsduration),st)
    }
    
    //  Range of the focused thumb is changed. Notify Property VC.
    func focusedClipChanged(_ start: Int,_ end:Int) {
        
        if let c = self.getFocusedClip() {
            c.setDuration(start, end)
        }
    }
    
    
    // MARK: - Save Clip -
    func saveSelectedClipAtLocation(dest:String, r:Duration) {
        
        let st = r.start-1
        let ed = r.end+1
        
        let queue1 = DispatchQueue(label: "com.ioutil.save", qos: DispatchQoS.background)
        queue1.async {
            
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let result = SaveClipWithInfo(Float(st), Float(ed), dest,observer, { (observer, current, total) -> Void in
                DispatchQueue.main.async {
                    //  update progress
                    if let observer = observer {
                        let myself = Unmanaged<VideoInfo>.fromOpaque(observer).takeUnretainedValue()
                        
                        if let p = myself.progress {
                            p.progressUpdated(Int(current), Int(total), false)
                        }
                    }
                }
            }, { (observer) -> Void in
                DispatchQueue.main.async {
                    if let observer = observer {
                        let myself = Unmanaged<VideoInfo>.fromOpaque(observer).takeUnretainedValue()
                        
                        if let p = myself.progress {
                            
                            p.progressUpdated(1, 1, true)
                        }
                    }
                    
                }
            })
            
            //  NOTE: Plan B for FFmpeg clip failed
            //  FFmpeg cannot copy streams that are detected but not correctly identified

            if result < 0 {
                do{
                    try FileManager.default.removeItem(atPath: dest)
                } catch{
                    print(error)
                }
                guard
                    let atts = try? FileManager.default.attributesOfItem(atPath: self.videopath),
                    let filesize = atts[.size] as? Int
                    else {
                        return
                }
                let total = filesize
                let st = r.start*total/self.tsduration
                let ed = r.end*total/self.tsduration
                let clipexporter = ClipExporter(sourcepath: self.videopath, destpath: dest, start: st, end: ed)
                
                clipexporter.saveClip(progress: { (current, max) in
                    DispatchQueue.main.async {
                        //  update progress
                        if let p = self.progress {
                        
                            p.progressUpdated(current, max, false)
                        }
                    }
                }) { (exporter) in
                    DispatchQueue.main.async {
                    
                        if let p = self.progress {
                            
                            p.progressUpdated(1, 1, true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - clips related -
    func deleteFocusedClip() {
        clips = clips.filter() { $0.isfocused != true }
    }
    // Delete Clip
    func deleteClipInfo(_ index:Int){
        if index < self.clips.count {
            self.clips.remove(at: index)
        }
    }
    func addClipInfo (_ s: Int, _ e:Int) {
        let c = ClipInfo()
        c.setDuration(s, e)
        self.clips.append(c)
    }
    func setFocusedClip(_ index:Int){
        var i:Int = 0
        clips.forEach { (c) in
            c.isfocused = false
            
            if i == index {
                clips[index].isfocused = true
            }
            i = i + 1
        }
    }
    func getFocusedClip() -> ClipInfo? {
        
        for c in clips {
            if c.isfocused {
                return c
            }
        }
        
        return nil
    }
    func getClipWithIndex(_ index:Int) -> ClipInfo? {
        if index < self.clips.count {
            return self.clips[index]
        }
        
        return nil
    }
    func getClipsCount() -> Int {
        return clips.count
    }
    
    
    // MARK: - memory issue...
    func loadVideoThumbnails(tick:Int, isEnd:Bool) -> CGImage?{
        if self.videopath.isEmpty {
            return nil
            
        }
        //  call clipVC to display thumb
        let imgref = getVideoThumbAtPosition(Double(tick))
        
        if imgref != nil {
            let thumb = imgref!.takeUnretainedValue()
            
            return thumb
        }
        return nil
        
    }
    
    
//    func playVideoWithClipRange() {
//        //  get clip range
//        let r = self.clipVC.getFocusedSliderRange()
//        let st = Float(r.x)*Float(tsduration)
//        let ed = Float(r.y)*Float(tsduration)
//
//
//        setPlayerCollapse(false)
//        let when = DispatchTime.now() + 1.0
//        DispatchQueue.main.asyncAfter(deadline: when, execute : {
//            self.playerVC.prepareVideo(start: st, end: ed, path: self.videopath)
//        })
//
//
//    }
    
}
