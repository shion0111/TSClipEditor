//
//  ClipEditViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 21/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

//
// MARK: - ClipEditViewController: VC for displaying clip thumbnails and handling slider functions
//

import Cocoa

protocol  MultipleRangeSliderDelegate {
    func focusedSliderChanged(start:Float, end:Float, view:Bool)
}
class ClipEditViewController: NSViewController, MultipleRangeSliderDelegate {
    
    var vidInfo:VideoInfoProtocol?
    @IBOutlet weak var clipStartThumb : NSImageView!
    @IBOutlet weak var clipEndThumb : NSImageView!
    @IBOutlet weak var clipSlider : MultipleRangeSlider!
    @IBOutlet weak var playButton : NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clipSlider.sliderDelegate = self
    }
    
    func setThumbnailImage(image : CGImage, isEnd: Bool){
        
        if isEnd {
            self.clipEndThumb.image = nil
            self.clipEndThumb.image = NSImage(cgImage: image, size: self.clipEndThumb.frame.size)
        } else {
            self.clipStartThumb.image = nil
            self.clipStartThumb.image = NSImage(cgImage: image, size: self.clipStartThumb.frame.size)
        }
    }
    func setSliderRange(start: Int, end:Int, calibration: Int){
        clipSlider.setSliderRange(start: start, end: end, calibration: calibration)
        self.playButton.isHidden = false
    }
    func addClipSliderThumb(){
        clipSlider.addClipSliderThumb()
        
    }
    func deleteFocusedSliderThumb(){
        clipSlider.deleteFocusedThumb()
    }
    func focusedSliderChanged(start:Float, end:Float, view:Bool){
        vidInfo?.focusedThumbRangeChanged(start: start, end: end, sliderlength: Float(clipSlider.horizontalline.frame.width), view: view)
    }
    func getFocusedSliderRange() -> NSPoint{
        let r = clipSlider.getFocusedClipPortion()
        return r
    }
    
    @IBAction func playClip(_ sender: AnyObject!){
        self.vidInfo?.playVideoWithClipRange()
    }
}
