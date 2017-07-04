//
//  ThumbView.swift
//  multipleRangeSliderTester
//
//  Created by Antelis on 28/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa

protocol ThumbPanDelegate {
    func leftPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView)
    func rightPanned(gesture: NSPanGestureRecognizer, thumb: RangeSliderThumbView)
    func notifyFocused(_ thumb: RangeSliderThumbView)//_ thumb:AnyObject?)
}

//@available(OSX 10.12, *)
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
    
    let left = NSImageView()
    let right = NSImageView()
    
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
    
    
    override func viewDidMoveToWindow() {
        self.Focused = true
        self.needsDisplay = true
    }
    @objc public func leftGesturePanned(gesture: NSPanGestureRecognizer) {
        
        self.panDelegate?.leftPanned(gesture: gesture, thumb: self)
        right.setFrameOrigin(NSPoint(x:self.frame.width - 14,y:0))
    }
    @objc public func rightGesturePanned(gesture: NSPanGestureRecognizer) {
        //print(self.frame.width)
        
        self.panDelegate?.rightPanned(gesture: gesture, thumb: self)
        right.setFrameOrigin(NSPoint(x:self.frame.width - 14,y:0))
    }
    @objc public func clickGestureHit(gesture: NSClickGestureRecognizer){
        self.Focused = !self.Focused
        
    }
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
        left.image = NSImage.init(imageLiteralResourceName: "NSLeftFacingTriangleTemplate")
        left.setFrameOrigin(NSPoint(x:2,y:0))
        left.setFrameSize(NSSize(width:9,height:fr.height))
        let lpan = NSPanGestureRecognizer(target: self, action:#selector(RangeSliderThumbView.leftGesturePanned(gesture:)))
        left.imageAlignment = .alignLeft
        left.addGestureRecognizer(lpan)
        self.addSubview(left)
        
        right.image = NSImage(imageLiteralResourceName: "NSRightFacingTriangleTemplate")
        right.setFrameOrigin(NSPoint(x:self.frame.width - 14,y:0))
        right.setFrameSize(NSSize(width:9,height:fr.height))
        let rpan = NSPanGestureRecognizer(target: self, action:#selector(RangeSliderThumbView.rightGesturePanned(gesture:)))
        right.imageAlignment = .alignRight
        right.addGestureRecognizer(rpan)
        self.addSubview(right)
        
        let click = NSClickGestureRecognizer(target: self, action: #selector(RangeSliderThumbView.clickGestureHit(gesture:)))
        self.addGestureRecognizer(click)
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if self.Focused{//thumbColor.isEqual(NSColor.lightGray) {
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
