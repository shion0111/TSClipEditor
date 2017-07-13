//
//  EditorWindowController.swift
//  TSClipEditor
//
//  Created by Antelis on 21/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa

class EditorWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else {
            
            fatalError("`window` is expected to be non nil by this time.")
            
        }

        window.isMovableByWindowBackground = true
        
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        
        
        window.appearance = NSAppearance(named: .vibrantDark)
        
    }

}
