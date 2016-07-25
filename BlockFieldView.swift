//
//  BlockFieldView.swift
//  BlockGraphEditor
//
//  Created by Hackintosh_PC2 on 2016/7/22.
//  Copyright © 2016年 mytest. All rights reserved.
//

import Cocoa

class BlockFieldView: NSView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    var fieldGraphManager:BlockFieldManager = BlockFieldManager()
    
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        super.mouseDragged(theEvent)
        
    }
    
}
