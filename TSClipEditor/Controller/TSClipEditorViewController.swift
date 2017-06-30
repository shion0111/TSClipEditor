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
    // Add Clip
    func addClipThumb() -> NSRange
    // Save Clip
    func saveClipAtLocation(path : String)
    // Delete Clip
    func deleteClipThumb()
    // SaveAll
    
}

class TSClipEditorViewController: NSSplitViewController,VideoInfoProtocol {
    
    @IBOutlet weak var propertyItem: NSSplitViewItem!
    @IBOutlet weak var clipViewItem: NSSplitViewItem!
    
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
        let duration = getVideoDurationWithLoc(path)
        //  display video thumbs at the start and the end
        loadVideoThumbnails(start:0, end:Int(duration - 1))
        var st = Int(ceil(Float(duration / 60)))
        if (st < 10) { st = 10 }
        if st > 20 {st = 20}
        self.clipVC.setSliderRange(start: 0, end: Int(duration),step: st)
        return Int(duration)
    }
    // Add Clip
    func addClipThumb() -> NSRange{
        
        return NSMakeRange(0, 1)
    }
    // Save Clip
    func saveClipAtLocation(path : String){
        
    }
    // Delete Clip
    func deleteClipThumb(){
        
    }
    
    func loadVideoThumbnails(start:Int, end:Int){
        
        //  call clipVC to display thumb
        let thumb = getVideoThumbAtPosition(0)!.takeUnretainedValue()
        self.clipVC.setThumbnailImage(image: thumb, isEnd: false)
        
        unowned let unownedSelf = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            let thumb = getVideoThumbAtPosition(Double(end))!.takeUnretainedValue()
            unownedSelf.clipVC.setThumbnailImage(image: thumb, isEnd: true)
        })
    }
    
}
