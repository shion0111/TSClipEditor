//
//  TSClipEditorViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 27/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa

protocol VideoInfoProtocol {
    //  retrieve video  metadata via ffmpeg
    func loadVideoWithPath(path : String) -> Int
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize)
    // Save Clip
    func saveClipAtLocation(source : String, dest:String)
    // Delete Clip
    func deleteClipThumb()
    
    func addClipThumb()
    //  Range of focused thumb is changed. Notify Property VC.
    func focusedThumbRangeChanged(start: Float, end:Float, sliderlength:Float)
    
}

class TSClipEditorViewController: NSSplitViewController,VideoInfoProtocol {
    
    @IBOutlet weak var propertyItem: NSSplitViewItem!
    @IBOutlet weak var clipViewItem: NSSplitViewItem!
    var tsduration : Int = 0
    
    // Left : TSPropertyViewController
    var prtVC : TSPropertyViewController {
        get{
            return propertyItem.viewController as! TSPropertyViewController
        }
    }
    // Right : ClipEditViewController
    var clipVC : ClipEditViewController {
        get{
            return clipViewItem.viewController as! ClipEditViewController
        }
    }
    var thumbViewHandler: ((CGImage, Bool) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prtVC.vidInfo = self
        self.clipVC.vidInfo = self
        //self.thumbViewHandler = clipVC.setThumbImage
    }
    
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize){
        
    }
    //  retrieve video  metadata via ffmpeg
    func loadVideoWithPath(path: String) -> Int {
        cleanContext()
        self.tsduration = Int(getVideoDurationWithLoc(path))
        
        var st = Int(ceil(Float(tsduration / 60)))
        if (st < 10) { st = 10 }
        if st > 20 {st = 20}
        self.clipVC.setSliderRange(start: 0, end: Int(tsduration),step: st)
        return Int(tsduration)
    }
    //  Range of focused thumb is changed. Notify Property VC.
    func focusedThumbRangeChanged(start: Float, end:Float, sliderlength:Float){
        let st = Int(ceil(Float(start/sliderlength)*Float(tsduration)))
        let ed = Int(ceil(Float(end/sliderlength)*Float(tsduration)))
        self.prtVC.clipRangeChanged(start: Float(st), end:Float(ed) )
        
        loadVideoThumbnails(start: st, end: ed)
    }
    func addClipThumb(){
        self.clipVC.addClipSliderThumb()
    }
    // Save Clip
    func saveClipAtLocation(source : String, dest:String) {
        
        //  get clip range first
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
                self.prtVC.updateSaveProgress(increment: current, max: max)
            }
        }) { (exporter) in
            DispatchQueue.main.async {
                self.prtVC.finishSaveProgress()
                clipexporter.closeExporter()
                
                /*
                let alert = NSAlert()
                alert.messageText = "Clip is saved!"
                alert.alertStyle = NSAlert.Style.informational
                alert.runModal()
                */
            }
        }
        
        
    }
    // Delete Clip
    func deleteClipThumb(){
        self.clipVC.deleteFocusedSliderThumb()
    }
    
    func loadVideoThumbnails(start:Int, end:Int){
        
        //  call clipVC to display thumb
        let thumb = getVideoThumbAtPosition(Double(start))!.takeUnretainedValue()
        self.clipVC.setThumbnailImage(image: thumb, isEnd: false)
        
        unowned let unownedSelf = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            let thumb = getVideoThumbAtPosition(Double(end))!.takeUnretainedValue()
            unownedSelf.clipVC.setThumbnailImage(image: thumb, isEnd: true)
        })
    }
    
}
