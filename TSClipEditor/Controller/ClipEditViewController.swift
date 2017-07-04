//
//  ClipEditViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 21/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa
protocol  MultipleRangeSliderDelegate {
    func focusedSliderChanged(start:Float, end:Float)
}
class ClipEditViewController: NSViewController, MultipleRangeSliderDelegate {
    
    var vidInfo:VideoInfoProtocol?
    @IBOutlet weak var clipStartThumb : NSImageView!
    @IBOutlet weak var clipEndThumb : NSImageView!
    @IBOutlet weak var clipSlider : MultipleRangeSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        //self.view.appearance = NSAppearance(named: .vibrantDark)//NSAppearanceNameVibrantDark)
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
    func setSliderRange(start: Int, end:Int, step: Int){
        clipSlider.setSliderRange(start: start, end: end, step: step)
    }
    func addClipSliderThumb(){
        clipSlider.addClipSliderThumb()
        
    }
    func deleteFocusedSliderThumb(){
        clipSlider.deleteFocusedThumb()
    }
    func focusedSliderChanged(start:Float, end:Float){
        vidInfo?.focusedThumbRangeChanged(start: start, end: end, sliderlength: Float(clipSlider.frame.width))
    }
    func getFocusedSliderRange() -> NSPoint{
        let r = clipSlider.getFocusedClipPortion()
        return r
    }
    
}
