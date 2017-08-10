//
//  ThumbView.swift
//  multipleRangeSliderTester
//
//  Created by Antelis on 28/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

// --------------------------------------------------
// MARK: - RangeSliderThumbView: Slider thumb can be extended by pan gesture
// --------------------------------------------------

import Cocoa

protocol ThumbPanDelegate {
    func leftPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView)
    func rightPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView)
    func notifyFocused(_ thumb: RangeSliderThumbView)//_ thumb:AnyObject?)
}


class RangeSliderThumbView: NSView {
    var max : Float = 0.0
    var min : Float = 0.0
    var panDelegate : ThumbPanDelegate?
    private var _focused: Bool = false
    var Focused : Bool {
        get { return _focused }
        set {
            _focused = newValue
            self.needsDisplay = true
            if _focused {
                panDelegate?.notifyFocused(self)
            }
        }
    }
    var thumbColor : NSColor = NSColor(red: 0.8, green: 0.90, blue: 1.0, alpha: 1.0)
    
    // left arrow and right arrow
    let left = NSView()
    let right = NSView()
    
    init(frame: CGRect, max: Float, min: Float){
        super.init(frame: frame)
        setup()
        self.max = max
        self.min = min
        
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    //  newly added and focused
    override func viewDidMoveToWindow() {
        if !_focused {
            self.Focused = true
            self.needsDisplay = true
        }
    }
    
    // update bounds by gesture
    @objc public func leftGesturePanned(gesture: NSPanGestureRecognizer) {
        
        self.panDelegate?.leftPanned(gesture: gesture, thumb: self)
        right.setFrameOrigin(NSPoint(x:self.frame.width - 14,y:0))
    }
    @objc public func rightGesturePanned(gesture: NSPanGestureRecognizer) {
        self.panDelegate?.rightPanned(gesture: gesture, thumb: self)
        right.setFrameOrigin(NSPoint(x:self.frame.width - 14,y:0))
    }
    
    //  clicked and focused
    //  there must be one focused thumb unless there's no thumbs at all in slider...
    @objc public func clickGestureHit(gesture: NSClickGestureRecognizer){
        if _focused { return }
        self.Focused = !self.Focused
        
    }
    //  set up the appearence
    func setup() {
        let fr = self.frame
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        /*
        if #available(OSX 10.13, *) {
            self.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
         */
        let lv = NSImageView()
        lv.image = NSImage.init(imageLiteralResourceName: "NSLeftFacingTriangleTemplate")
        lv.setFrameOrigin(NSPoint(x:2,y:0))
        lv.setFrameSize(NSSize(width:9,height:fr.height))
        let lpan = NSPanGestureRecognizer(target: self, action:#selector(RangeSliderThumbView.leftGesturePanned(gesture:)))
        lv.imageAlignment = .alignLeft
        
        left.setFrameOrigin(NSPoint(x:0, y:0))
        left.setFrameSize(NSSize(width: 15, height: fr.height))
        left.addSubview(lv)
        left.addGestureRecognizer(lpan)
        self.addSubview(left)
        
        let rv = NSImageView()
        rv.image = NSImage(imageLiteralResourceName: "NSRightFacingTriangleTemplate")
        rv.setFrameOrigin(NSPoint(x:2,y:0))
        rv.setFrameSize(NSSize(width:9,height:fr.height))
        let rpan = NSPanGestureRecognizer(target: self, action:#selector(RangeSliderThumbView.rightGesturePanned(gesture:)))
        rv.imageAlignment = .alignRight
        
        right.setFrameOrigin(NSPoint(x: self.frame.width - 14, y: 0))
        right.setFrameSize(NSSize(width: 15, height: fr.height))
        right.addSubview(rv)
        right.addGestureRecognizer(rpan)
        self.addSubview(right)
        
        
        let click = NSClickGestureRecognizer(target: self, action: #selector(RangeSliderThumbView.clickGestureHit(gesture:)))
        self.addGestureRecognizer(click)
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if self.Focused{
            self.thumbColor = .systemBlue
        } else {
            self.thumbColor = .lightGray
        }
        
        let fr = self.frame
        
        let p = NSBezierPath()
        
        thumbColor.set()
        p.move(to:NSPoint(x: 15,y: 2.5))
        p.line(to:NSPoint(x: fr.size.width-15,y: 2.5))
        p.lineWidth = 5.0
        p.stroke()
        
        p.move(to:NSPoint(x: 15,y: fr.size.height-2.5))
        p.line(to:NSPoint(x: fr.size.width-15,y: fr.size.height-2.5))
        p.stroke()
        
        let p2 = NSBezierPath()
        p2.lineWidth = 15.0
        p2.move(to:NSPoint(x: 7.5,y: 0))
        p2.line(to:NSPoint(x: 7.5,y: fr.size.height))
        p2.stroke()
        p2.move(to:NSPoint(x: fr.size.width-7.5,y: 0))
        p2.line(to:NSPoint(x: fr.size.width-7.5,y: fr.size.height))
        p2.stroke()
        
    }
    
}
