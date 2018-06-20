//
//  VideoInfo.swift
//  TSClipEditor
//
//  Created by Antelis on 2018/6/3.
//  Copyright © 2018 shion. All rights reserved.
//

import Foundation
class ClipInfo :NSObject {
    var start :Int = 0
    var end: Int = 1
    var index: Int = 0
    var isfocused: Bool = false
    
    func setDuration(_ s: Int, _ e: Int) {
        self.start = s
        self.end = e
    }
    
}
class VideoInfo: VideoInfoProtocol {
    
    //,CAAnimationDelegate {
    var clips : [ClipInfo] = []
    var tsduration : Int = 0
    var videopath: String = ""
    var thumbViewHandler: ((CGImage, Bool) -> ())?
    
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize){
        
    }
    
    //  retrieve video duration/metadata via ffmpeg
    func loadVideoWithPath(path: String) -> (Int,Int) {
        videopath = path
        cleanVideoContext()
        self.tsduration = Int(getVideoDurationWithLoc(path))
        
        let st = 20
        return (Int(tsduration),st)
    }
    
    //  Range of the focused thumb is changed. Notify Property VC.
    func focusedClipChanged(_ index: Int,_ start: Int,_ end:Int) {
        
        if index >= 0 && index < self.clips.count {
            let c = clips[index]
            c.setDuration(start, end)
        }
    }
    // Save Clip
    func saveClipAtLocation(source : String, dest:String, r:NSPoint) {
        
        let total = self.tsduration
        let st = ceil(Float(r.x)*Float(total))-1
        let ed = ceil(Float(r.y)*Float(total))+1
        
        let queue1 = DispatchQueue(label: "com.ioutil.save", qos: DispatchQoS.background)
        queue1.async {
            // Void pointer to `self`:
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let result = SaveClipWithInfo(st, ed, dest,observer, { (observer, current, total) -> Void in
                DispatchQueue.main.async {
                    if let observer = observer {
                        //let myself = Unmanaged<TSClipEditorViewController>.fromOpaque(observer).takeUnretainedValue()
                        //myself.clipVC.updateSaveProgress(Int(current),Int(total))
                        //print("progress: \(current)/\(total)")
                    }
                }
            }, { (observer) -> Void in
                DispatchQueue.main.async {
                    if let observer = observer {
                        //let myself = Unmanaged<TSClipEditorViewController>.fromOpaque(observer).takeUnretainedValue()
                        //myself.clipVC.finishSaveProgress()
                    }
                    
                }
            })
            
            //  FFmpeg cannot copy streams that are detected but not correctly identified
            //  possibly a plan b is needed...
            if result < 0 {
                do{
                    try FileManager.default.removeItem(atPath: dest)
                } catch{
                    print(error)
                }
                guard
                    let atts = try? FileManager.default.attributesOfItem(atPath: source),
                    let filesize = atts[.size] as? Int
                    else {
                        return
                }
                let total = filesize
                let st = Int(ceil(Float(r.x)*Float(total)))
                let ed = Int(ceil(Float(r.y)*Float(total)))
                let clipexporter = ClipExporter(sourcepath: source, destpath: dest, start: st, end: ed)
                
                clipexporter.saveClip(progress: { (current, max) in
                    DispatchQueue.main.async {
                        //self.clipVC.updateSaveProgress(current, max)
                    }
                }) { (exporter) in
                    DispatchQueue.main.async {
                        //self.clipVC.finishSaveProgress()
                    }
                }
            }
        }
        
        
        
        
    }
    // Delete Clip
    func deleteClipInfo(_ index:Int){
        if index < self.clips.count {
            self.clips.remove(at: index)
        }
    }
    func hasFocusedThumb() -> Bool{
        //let r = self.clipVC.getFocusedSliderRange()
        return false//(r.y-r.x) > 0
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
    func addClipInfo (_ s: Int, _ e:Int) {
        let c = ClipInfo()
        c.setDuration(s, e)
        self.clips.append(c)
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
