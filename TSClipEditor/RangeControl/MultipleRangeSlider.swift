//
//  testSlider.swift
//  MultipleRangeSlider
//
//  Created by Antelis on 28/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

// --------------------------------------------------
// MARK: - MultipleRangeSlider: A slider contains multiple thumbs to mark several regions
// --------------------------------------------------

import Cocoa

protocol  MultipleRangeSliderDelegate {
    func focusedSliderChanged(focused:AnyObject?, start:Float, end:Float, view:Bool)
}

class MultipleRangeSlider: NSView,ThumbPanDelegate {
    
    var sliderDelegate : MultipleRangeSliderDelegate?
    var endLabel: NSTextField?
    
    var start : Int = 0
    var end : Int = 0
    var calibration : Int = 0
    
    var thumbs = [RangeSliderThumbView]()
    let horizontalline = NSBox()
    var xoffset : CGFloat = 0
    
    override func awakeFromNib() {
        xoffset = 12
        setAccessoryViews()
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
                if st == 0 || st == self.calibration {
                    NSBezierPath.strokeLine(from: NSPoint(x:x,y:y), to: NSPoint(x:x, y: y-32))
                } else {
                    NSBezierPath.strokeLine(from: NSPoint(x:x,y:y), to: NSPoint(x:x, y: y-8))
                }
            }
            NSBezierPath.strokeLine(from: NSPoint(x:r0.origin.x,y:r0.origin.y-36), to: NSPoint(x:r0.origin.x+r0.width, y: r0.origin.y-36))
        }
        
    }
    func setAccessoryViews(){
        
        horizontalline.boxType = .separator
        horizontalline.setFrameOrigin(NSPoint(x:12, y:self.frame.height-16))
        horizontalline.setFrameSize(NSSize(width:self.frame.width - 24,height:2))
        self.addSubview(horizontalline)
        horizontalline.wantsLayer = true
        horizontalline.layer?.shadowColor = NSColor.white.cgColor
        horizontalline.layer?.shadowOpacity = 0.7
        horizontalline.layer?.shadowOffset = CGSize.zero
        horizontalline.layer?.shadowRadius = 5.0
        horizontalline.layer?.masksToBounds = false
        horizontalline.isHidden = true
        
        
        endLabel = NSTextField(frame: NSMakeRect(self.frame.width-215, self.frame.height-50, 194, 17))
        endLabel?.alignment = .right
        endLabel?.textColor = NSColor.white
        self.addSubview(endLabel!)
        endLabel?.isEditable = false
        endLabel?.isBezeled = false
        endLabel?.drawsBackground = false
        endLabel?.stringValue = "00:00:00"
        endLabel?.isHidden = true
        
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
        
        if end == 0 {
            return
        }
        
        let r = getRectByCalibration(0)
        self.addThumbViewWithRect(rect: r)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        endLabel?.stringValue = "\(formatter.string(from: TimeInterval(end))!) (\(end) Sec.)"
        endLabel?.isHidden = false
        horizontalline.isHidden = false
        
    }
    func resetThumbs(){
        
        for t in self.thumbs {
            t.removeFromSuperview()
        }
        self.thumbs.removeAll()
        
    }
    
    func addClipSliderThumb(){
        // add new
        let r = findUnoccupiedRect()//getRectByCalibration(self.calibration/2)
        let focused = addThumbViewWithRect(rect: r)
        if r.origin.x - xoffset < 0 {
            return
        }
        sliderDelegate?.focusedSliderChanged(focused:focused, start:Float(r.origin.x - xoffset) , end: Float(r.origin.x + r.width - xoffset),view: true)
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
    
    //  minimal width of thumb is 35
    func findUnoccupiedRect() -> NSRect{
        let total = Int(self.horizontalline.frame.width / 35)
        let y = self.horizontalline.frame.origin.y - 15
        for i in 0..<total {
            let rct = NSRect(x: i*35, y:Int(y) , width: 35, height: 30)
            if !(self.isRectIntersectsOtherThumb(rect: rct, thumb: nil)) {
                
                return rct
            }
        }
        return NSZeroRect
    }
    
    // MARK: - ThumbPanDelegate functions
    func addThumbViewWithRect(rect: CGRect) -> RangeSliderThumbView {
        
        let thumb = RangeSliderThumbView(frame: rect, max:Float(rect.origin.x) , min:Float(rect.origin.x+rect.width) )//CGRect(x:12,y:self.frame.height/2-15,width:60,height:30))
        
        if rect.origin.x == 0 {
            let p = rect.origin
            thumb.setFrameOrigin(NSPoint(x:xoffset, y:p.y))
        }
        
        thumb.thumbColor = .lightGray//.systemBlue-
        thumb.panDelegate = self
        self.thumbs.append(thumb)
        self.addSubview(thumb)
        
        return thumb
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
    private func isRectIntersectsOtherThumb(rect: NSRect, thumb: RangeSliderThumbView?) -> Bool{
        for t in self.thumbs{
            if (thumb == nil) || (t != thumb) {
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
            sliderDelegate?.focusedSliderChanged(focused:thumb, start:Float(thumb.frame.origin.x - xoffset) , end: Float(thumb.frame.origin.x + thumb.frame.width - xoffset), view: (gesture.state == .ended))
        }
        
    }
    func rightPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView){
        
        if thumb.Focused {
            
//            if isPointInOtherThumb(p: gesture.location(in: self),thumb: thumb) {
//                return
//            }
            
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
            sliderDelegate?.focusedSliderChanged(focused: thumb, start:Float(thumb.frame.origin.x - xoffset) , end: Float(thumb.frame.origin.x + thumb.frame.width - xoffset), view: (gesture.state == .ended))
        }
        
    }
   
    func notifyFocused(_ thumb: RangeSliderThumbView) {
        for t in self.thumbs{
            if t != thumb {
                t.Focused = false
            }
        }
        //print(thumb)
        sliderDelegate?.focusedSliderChanged(focused: thumb, start:Float(thumb.frame.origin.x - xoffset) , end: Float(thumb.frame.origin.x + thumb.frame.width - xoffset), view:true)
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
    
    func updateFocusedPosition(_ s: Int, _ e: Int) {
        for t in self.thumbs{
            if t.Focused {
                print("param \(s),\(e)")
                let ss = self.end - self.start
                let ww = Int(self.horizontalline.frame.width)
                var xs = ww*s/ss
                if CGFloat(xs) < xoffset {
                    xs = Int(xoffset)
                }
                var xe = ww*(e-s)/ss
                if xe < Int(xoffset) {
                    xe = Int(xoffset)
                }
                let rc = t.frame
                print("param x \(xs),\(xe)")
                t.setFrameOrigin(NSPoint(x:CGFloat(xs), y:rc.origin.y))
                t.setFrameSize(NSSize(width: CGFloat(xe) , height: rc.size.height))
                t.setNeedsDisplay(t.frame)
            }
        }
    }
    
}
