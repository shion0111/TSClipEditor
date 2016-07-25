//
//  BlockView.swift
//  BlockGraphEditor
//
//  Created by Hackintosh_PC2 on 2016/7/22.
//  Copyright © 2016年 mytest. All rights reserved.
//

import Cocoa

class BlockView: NSView {

    var data:BlockData
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    
    
    required init(frame: NSRect, dtype:Int32){
    
        data = BlockData(dataType: dtype)
        super.init(frame:frame)
        
        
        
    }
    
    required init?(coder: NSCoder) {
        data = BlockData(dataType: 0)
        super.init(coder: coder)
    }
    
    
}
