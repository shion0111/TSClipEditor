//
//  testSlider.swift
//  MultipleRangeSlider
//
//  Created by Antelis on 28/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa
class MultipleRangeSlider: NSView,ThumbPanDelegate {
    
    var start : Int = 0
    var end : Int = 0
    var step : Int = 0
    //var thumbView: RangeSliderThumbView!
    var thumbs = [RangeSliderThumbView]()
    let horizontalline = NSBox()
    /*
    var right : CGFloat {
        get {
            return thumbView.frame.origin.x+thumbView.frame.size.width
        }
        set {}
    }
 */
    override func awakeFromNib() {
        
        horizontalline.boxType = .separator
        horizontalline.setFrameOrigin(NSPoint(x:12, y:self.frame.height/2))
        horizontalline.setFrameSize(NSSize(width:self.frame.width - 24,height:2))
        self.addSubview(horizontalline)//, positioned:.below, relativeTo:self.thumbView)
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let r0 = self.horizontalline.frame
        if self.step > 0 {
            
            let distance = r0.width//self.end - self.start
            let r = CGFloat(distance / CGFloat(self.step))
            
            NSColor.systemGray.setStroke()
            
            for st in 0...self.step{
                let x = r0.origin.x + r*CGFloat(st)
                let y = r0.origin.y - r0.height - 2
                NSBezierPath.strokeLine(from: NSPoint(x:x,y:y), to: NSPoint(x:x, y: y-8))
            }
        }
        
    }
    func getRectByStep(_ st : Int) -> CGRect {
        let r0 = self.horizontalline.frame
        let distance = r0.width//self.end - self.start
        let r = CGFloat(distance / CGFloat(self.step))
            
        return CGRect(x: CGFloat(st)*r+r0.origin.x, y:r0.origin.y-15 , width: CGFloat(st+1)*r, height: 30)
        
    }
    func setSliderRange(start: Int, end: Int, step : Int){
        resetThumbs()
        self.start = start
        self.end = end
        self.step = step
        self.needsDisplay = true
        
        self.addThumbView(rect: getRectByStep(0))
    }
    func resetThumbs(){
        
        for t in self.thumbs {
            t.removeFromSuperview()
        }
        self.thumbs.removeAll()
        
    }
    
    // MARK: - ThumbPanDelegate functions
    func addThumbView(rect: CGRect){
        
        let thumb = RangeSliderThumbView(frame: rect, max:Float(rect.origin.x) , min:Float(rect.origin.x+rect.width) )//CGRect(x:12,y:self.frame.height/2-15,width:60,height:30))
        
        thumb.thumbColor = .lightGray//.systemBlue-
        thumb.panDelegate = self
        self.thumbs.append(thumb)
        self.addSubview(thumb)
    }
    func leftPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView){
        
        if thumb.Focused {
        
            var destx = gesture.location(in: self).x
            if destx < 12 {
                destx = 12
            }
            let rc = thumb.frame
            if rc.width < 35 && (rc.origin.x+rc.width - destx) < rc.width {
                return
            }
            
            thumb.setFrameOrigin(NSPoint(x:destx, y:rc.origin.y))
            thumb.setFrameSize(NSSize(width: rc.origin.x+rc.width - destx , height: rc.size.height))
            thumb.setBoundsSize(NSSize(width: rc.origin.x+rc.width - destx , height: rc.size.height))
        }
        
    }
    func rightPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView){
        
        if thumb.Focused {
            var destx = gesture.location(in: self).x
            let rc = thumb.frame
            
            if rc.width < 35 && (destx - rc.origin.x) < rc.width {
                return
            }
            
            if destx > (horizontalline.frame.width+horizontalline.frame.origin.x){
                destx = horizontalline.frame.width+horizontalline.frame.origin.x
            }
            thumb.setFrameSize(NSSize(width: destx - rc.origin.x , height: rc.size.height))
            thumb.setBoundsSize(NSSize(width: destx - rc.origin.x , height: rc.size.height))
        }
        
    }
    func notifyFocused(_ thumb: RangeSliderThumbView) {
        print(thumb)
    }
    /*
    func notifyFocused(_ thumb: AnyObject?) {
        let t = thumb as? RangeSliderThumbView
        t != nil ? print(t!) : print("thumb is nil!")
        
    }
     */
}
