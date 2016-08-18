//
//  DarkWindow.swift
//  BlockGraphEditor
//
//  Created by Antelis on 2016/8/11.

//

import Cocoa

class DarkWindow: NSWindow {
    /*
    override var effectiveAppearance: NSAppearance {
        return NSAppearance(named: NSAppearanceNameVibrantDark)!
    }
    */
    override func awakeFromNib() {
        self.styleMask = self.styleMask | NSFullSizeContentViewWindowMask
        self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        
        titleVisibility = NSWindowTitleVisibility.Hidden
        

    }
    
    override var contentView: NSView? {
        set {
            if let view = newValue
            {
                view.wantsLayer = true
                let colorTop = NSColor(red: 64 / 255, green: 64 / 255, blue: 64 / 255, alpha: 1).CGColor//31 / 255, green: 37 / 255, blue: 43 / 255, alpha: 1).CGColor
                let colorBottom = NSColor(red: 41 / 255, green: 47 / 255, blue: 53 / 255, alpha: 1).CGColor
                let gradient  = CAGradientLayer()
                gradient.colors = [ colorTop, colorBottom]
                gradient.locations = [ 0.0, 1.0]
                view.layer = gradient
                
            }
            super.contentView = newValue
            
        }
        get {
            return super.contentView
        }
    }
}



/*
 Unit : block view (focus/move/in/out/collision area)
	blockData : type/in/out/
 Block field --> NSView
	- Graph redraw, rearrange
	BlockFieldManager
 - Graph data
 block view is DnD
 Blocklist view
	DnD handler
 Only one collision area is available at one time
 connecting line has no interaction
 
 
 
 */