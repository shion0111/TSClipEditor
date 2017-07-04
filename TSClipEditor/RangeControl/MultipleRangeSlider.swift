//
//  testSlider.swift
//  MultipleRangeSlider
//
//  Created by Antelis on 28/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//
// --------------------------------------------------
// MARK: - A Slider with multiple thumbs, to mark up regions
// --------------------------------------------------

import Cocoa

class MultipleRangeSlider: NSView,ThumbPanDelegate {
    
    var sliderDelegate : MultipleRangeSliderDelegate?
    
    var start : Int = 0
    var end : Int = 0
    var calibration : Int = 0
    
    var thumbs = [RangeSliderThumbView]()
    let horizontalline = NSBox()
    var xoffset : CGFloat = 0
    
    override func awakeFromNib() {
        
        horizontalline.boxType = .separator
        horizontalline.setFrameOrigin(NSPoint(x:12, y:self.frame.height/2))
        horizontalline.setFrameSize(NSSize(width:self.frame.width - 24,height:2))
        self.addSubview(horizontalline)
        xoffset = 12
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let r0 = self.horizontalline.frame
        if self.calibration > 0 {
            
            let distance = r0.width//self.end - self.start
            let r = CGFloat(distance / CGFloat(self.calibration))
            
            NSColor.systemGray.setStroke()
            
            for st in 0...self.calibration{
                let x = r0.origin.x + r*CGFloat(st)
                let y = r0.origin.y - r0.height - 2
                NSBezierPath.strokeLine(from: NSPoint(x:x,y:y), to: NSPoint(x:x, y: y-8))
            }
        }
        
    }
    func getRectByCalibration(_ st : Int) -> CGRect {
        let r0 = self.horizontalline.frame
        let distance = r0.width//self.end - self.start
        let r = CGFloat(distance / CGFloat(self.calibration))
            
        return CGRect(x: CGFloat(st)*r+r0.origin.x, y:r0.origin.y-15 , width: r, height: 30)
        
    }
    func setSliderRange(start: Int, end: Int, calibration : Int){
        resetThumbs()
        self.start = start
        self.end = end
        self.calibration = calibration
        self.needsDisplay = true
        
        let r = getRectByCalibration(0)
        self.addThumbViewWithRect(rect: r)
        
    }
    func resetThumbs(){
        
        for t in self.thumbs {
            t.removeFromSuperview()
        }
        self.thumbs.removeAll()
        
    }
    func addClipSliderThumb(){
        // add new
        let r = getRectByCalibration(self.calibration/2)
        addThumbViewWithRect(rect: r)
        sliderDelegate?.focusedSliderChanged(start:Float(r.origin.x - xoffset) , end: Float(r.origin.x + r.width - xoffset),view: true)
    }
    func deleteFocusedThumb(){
        // delete and move to next
        for t in self.thumbs{
            if t.Focused {
                if let index = self.thumbs.index(of: t){
                    self.thumbs.remove(at: index)
                }
                t.removeFromSuperview()
            }
        }
        
        if self.thumbs.count > 0 {
        // pick the first thumb as focused...
            let t = self.thumbs[0]
            t.Focused = true
        }
        
    }
    // MARK: - ThumbPanDelegate functions
    func addThumbViewWithRect(rect: CGRect){
        
        let thumb = RangeSliderThumbView(frame: rect, max:Float(rect.origin.x) , min:Float(rect.origin.x+rect.width) )//CGRect(x:12,y:self.frame.height/2-15,width:60,height:30))
        
        thumb.thumbColor = .lightGray//.systemBlue-
        thumb.panDelegate = self
        self.thumbs.append(thumb)
        self.addSubview(thumb)
    }
    private func isPointInOtherThumb(p:NSPoint, thumb: RangeSliderThumbView) -> Bool{
        for t in self.thumbs{
            if t != thumb {
                if NSPointInRect(p,t.frame){
                    return true
                }
            }
        }
        
        return false
    }
    private func isRectIntersectsOtherThumb(rect: NSRect, thumb: RangeSliderThumbView) -> Bool{
        for t in self.thumbs{
            if t != thumb {
                if rect.intersects(t.frame){
                    return true
                }
            }
        }
        
        return false
    }
    
    func leftPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView){
        if thumb.Focused {
            
            if isPointInOtherThumb(p: gesture.location(in: self),thumb: thumb) {
                return
            }
            
            var destx = gesture.location(in: self).x
            if destx < 12 {
                destx = 12
            }
            let rc = thumb.frame
            if rc.width < 35 && (rc.origin.x+rc.width - destx) < rc.width {
                return
            }
            
            let r2 = NSRect(x:destx,y:rc.origin.y,width:rc.origin.x+rc.width - destx ,height:rc.size.height)
            if self.isRectIntersectsOtherThumb(rect: r2, thumb: thumb){
                return
            }
            
            thumb.setFrameOrigin(NSPoint(x:destx, y:rc.origin.y))
            thumb.setFrameSize(NSSize(width: rc.origin.x+rc.width - destx , height: rc.size.height))
            thumb.setBoundsSize(NSSize(width: rc.origin.x+rc.width - destx , height: rc.size.height))            
            sliderDelegate?.focusedSliderChanged(start:Float(thumb.frame.origin.x - xoffset) , end: Float(thumb.frame.origin.x + thumb.frame.width - xoffset), view: (gesture.state == .ended))
        }
        
    }
    func rightPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView){
        
        if thumb.Focused {
            
            if isPointInOtherThumb(p: gesture.location(in: self),thumb: thumb) {
                return
            }
            
            var destx = gesture.location(in: self).x
            let rc = thumb.frame
            
            if rc.width < 35 && (destx - rc.origin.x) < rc.width {
                return
            }
            
            if destx > (horizontalline.frame.width+horizontalline.frame.origin.x){
                destx = horizontalline.frame.width+horizontalline.frame.origin.x
            }
            
            let r2 = NSRect(x:destx,y:rc.origin.y,width:rc.origin.x+rc.width - destx ,height:rc.size.height)
            if self.isRectIntersectsOtherThumb(rect: r2, thumb: thumb){
                return
            }
            
            thumb.setFrameSize(NSSize(width: destx - rc.origin.x , height: rc.size.height))
            thumb.setBoundsSize(NSSize(width: destx - rc.origin.x , height: rc.size.height))
            sliderDelegate?.focusedSliderChanged(start:Float(thumb.frame.origin.x - xoffset) , end: Float(thumb.frame.origin.x + thumb.frame.width - xoffset), view: (gesture.state == .ended))
        }
        
    }
    func notifyFocused(_ thumb: RangeSliderThumbView) {
        for t in self.thumbs{
            if t != thumb {
                t.Focused = false
            }
        }
        //print(thumb)
        sliderDelegate?.focusedSliderChanged(start:Float(thumb.frame.origin.x - xoffset) , end: Float(thumb.frame.origin.x + thumb.frame.width - xoffset), view:true)
    }
    func getFocusedClipPortion() -> NSPoint{
        for t in self.thumbs{
            if t.Focused {
                let x0 = t.frame.origin.x - xoffset
                let x1 = t.frame.origin.x + t.frame.width - xoffset
                print("x0: \(x0), x1: \(x1)")
                return NSMakePoint(x0/horizontalline.frame.width , x1/horizontalline.frame.width)
            }
        }
        return NSMakePoint(0,0)
    }
    
}
