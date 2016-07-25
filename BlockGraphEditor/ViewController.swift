//
//  ViewController.swift
//  BlockGraphEditor
//
//  Created by Hackintosh_PC2 on 2016/7/22.
//  Copyright © 2016年 mytest. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
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