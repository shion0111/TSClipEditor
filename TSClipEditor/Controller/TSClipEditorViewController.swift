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

protocol VideoInfoProtocol {
    //  retrieve video  metadata via ffmpeg
    func loadVideoWithPath(path : String) -> Int
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize)
    // Save clip
    func saveClipAtLocation(source : String, dest:String)
    // Delete clip
    func deleteClipThumb()
    //  Add new clip
    func addClipThumb()
    //  Range of focused thumb is changed. Notify Property VC.
    func focusedThumbRangeChanged(start: Float, end:Float, sliderlength:Float, view:Bool)
    
    func hasFocusedThumb() -> Bool
    
    func playVideoWithClipRange()
}

class TSClipEditorViewController: NSSplitViewController,VideoInfoProtocol {
    
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
        self.clipVC.vidInfo = self
        
    }
    
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize){
        
    }
    
    //  retrieve video duration/metadata via ffmpeg
    func loadVideoWithPath(path: String) -> Int {
        videopath = path
        cleanContext()
        self.tsduration = Int(getVideoDurationWithLoc(path))
    
        let st = 20
        self.clipVC.setSliderRange(start: 0, end: Int(tsduration),calibration: st)
        return Int(tsduration)
    }
    
    //  Range of the focused thumb is changed. Notify Property VC.
    func focusedThumbRangeChanged(start: Float, end:Float, sliderlength:Float,view:Bool){
        let st = Float(start/sliderlength)*Float(tsduration)
        let ed = Float(end/sliderlength)*Float(tsduration)
        //self.prtVC.clipRangeChanged(start: Float(st), end:Float((ed > Float(tsduration)) ? Float(tsduration) : ed) )
        
        //if view {
        loadVideoThumbnails(start: Int(st), end: Int(ed))
        //}
    }
    
    func addClipThumb(){
        self.clipVC.addClipSliderThumb()
    }
    
    // Save Clip
    func saveClipAtLocation(source : String, dest:String) {
        
        //  get clip range
        let r = self.clipVC.getFocusedSliderRange()
        //  get size of source
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
                //self.prtVC.updateSaveProgress(increment: current, max: max)
            }
        }) { (exporter) in
            DispatchQueue.main.async {
                //self.prtVC.finishSaveProgress()
                clipexporter.closeExporter()
                
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
    func playVideoWithClipRange(){
        
        playerItem.animator().isCollapsed = false
        playerItem.canCollapse = false
        //  get clip range
        let r = self.clipVC.getFocusedSliderRange()
        let st = Float(r.x)*Float(tsduration)
        let ed = Float(r.y)*Float(tsduration)
        
        /*
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let preview = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("PreviewWindow")) as! NSWindowController
        let vidVC = preview.contentViewController as! VideoPlayerViewController
         */
        self.playerVC.prepareVideo(start: st, end: ed, path: videopath)
        //preview.window?.appearance = NSAppearance(named: .vibrantDark)
        //preview.window?.makeKeyAndOrderFront(nil)

        
    }
    
}
