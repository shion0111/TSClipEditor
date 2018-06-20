//
//  TSClipEditorViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 27/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

//
// MARK: - TSClipEditorViewController: major function handler, info exchange
//
import Cocoa



class TSClipEditorViewController: NSSplitViewController,VideoInfoProtocol {
    //,CAAnimationDelegate {
    
    @IBOutlet weak var playerItem: NSSplitViewItem!
    @IBOutlet weak var clipViewItem: NSSplitViewItem!
    var tsduration : Int = 0
    var videopath: String!
    
    /*
    // Left : TSPropertyViewController
    var prtVC : TSPropertyViewController {
        get{
            return propertyItem.viewController as! TSPropertyViewController
        }
    }
    */
    // Left : ClipEditViewController
    var clipVC : ClipEditViewController {
        get{
            return clipViewItem.viewController as! ClipEditViewController
        }
    }
    // Right : VideoPlayerViewController
    var playerVC : VideoPlayerViewController{
        get{
            return playerItem.viewController as! VideoPlayerViewController
        }
    }
    
    var thumbViewHandler: ((CGImage, Bool) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.prtVC.vidInfo = self
        self.playerVC.vidInfo = self
        self.clipVC.vidInfo = self
        
    }
    
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize){
        
    }
    
    //  retrieve video duration/metadata via ffmpeg
    func loadVideoWithPath(path: String) -> (Int,Int) {
        videopath = path
        cleanVideoContext()
        self.tsduration = Int(getVideoDurationWithLoc(path))
    
        let st = 20
        self.clipVC.setSliderRange(start: 0, end: Int(tsduration),calibration: st)
        self.playerVC.cleanup()
        return (Int(tsduration),st)
    }
    
    //  Range of the focused thumb is changed. Notify Property VC.
    func focusedThumbRangeChanged(focused: AnyObject?, start: Float, end:Float, sliderlength:Float, view:Bool) {
        let st = Float(start/sliderlength)*Float(tsduration)
        let ed = Float(end/sliderlength)*Float(tsduration)
        
        //self.prtVC.clipRangeChanged(start: Float(st), end:Float((ed > Float(tsduration)) ? Float(tsduration) : ed) )
        
        //if view {
        loadVideoThumbnails(start: Int(st), end: Int(ed))
        //}
    }
    // Save Clip
    func saveClipAtLocation(source : String, dest:String,r:NSPoint) {
        

        
        
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
                        let myself = Unmanaged<TSClipEditorViewController>.fromOpaque(observer).takeUnretainedValue()
                        myself.clipVC.updateSaveProgress(Int(current),Int(total))
                        //print("progress: \(current)/\(total)")
                    }
                }
            }, { (observer) -> Void in
                DispatchQueue.main.async {
                    if let observer = observer {
                        let myself = Unmanaged<TSClipEditorViewController>.fromOpaque(observer).takeUnretainedValue()
                        myself.clipVC.finishSaveProgress()
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
                        self.clipVC.updateSaveProgress(current, max)
                    }
                }) { (exporter) in
                    DispatchQueue.main.async {
                        self.clipVC.finishSaveProgress()                                            
                    }
                }
            }
        }
        
        
        
        
    }
    // Delete Clip
    func deleteClipThumb(){
        self.clipVC.deleteFocusedSliderThumb()
    }
    func hasFocusedThumb() -> Bool{
        let r = self.clipVC.getFocusedSliderRange()
        return (r.y-r.x) > 0
    }
    
    // MARK: - memory issue...
    func loadVideoThumbnails(start:Int, end:Int){
        
        //  call clipVC to display thumb
        let imgref = getVideoThumbAtPosition(Double(start))
        
        if imgref != nil {
            let thumb = imgref!.takeUnretainedValue()
            self.clipVC.setThumbnailImage(image: thumb, isEnd: false)
            
            
            
            unowned let unownedSelf = self
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                let thumb = getVideoThumbAtPosition(Double(end))!.takeUnretainedValue()
                unownedSelf.clipVC.setThumbnailImage(image: thumb, isEnd: true)
            })
        }
     
    }
    func setPlayerCollapse(_ c: Bool) {
        /*
        let animation = CAAnimation()
        animation.delegate = self
        playerItem.animations = [NSAnimatablePropertyKey(rawValue: "collapsed"):animation]
         */
        playerItem.isCollapsed = c
        
    }
    
    func collapseClipViewController() {
        setPlayerCollapse(true)
    }
    func playVideoWithClipRange() {
        //  get clip range
        let r = self.clipVC.getFocusedSliderRange()
        let st = Float(r.x)*Float(tsduration)
        let ed = Float(r.y)*Float(tsduration)
        
        
        setPlayerCollapse(false)
        let when = DispatchTime.now() + 1.0
        DispatchQueue.main.asyncAfter(deadline: when, execute : {
            self.playerVC.prepareVideo(start: st, end: ed, path: self.videopath)
        })
        
        
    }
    
}
