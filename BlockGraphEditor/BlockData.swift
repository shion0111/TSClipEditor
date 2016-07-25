//
//  BlockData.swift
//  BlockGraphEditor
//
//  Created by Hackintosh_PC2 on 2016/7/22.
//  Copyright © 2016年 mytest. All rights reserved.
//

import Foundation
import AppKit

class BlockData{
    
    var type: Int32 = 0
    
    var source = [BlockData]()
    var dest = [BlockData]()
    
    var blockRect:CGRect = CGRect.zero
    
    init(dataType:Int32) {
        
        type = dataType;
    }
    
    func addSource(sourceBlock:BlockData) -> Bool {
    
        return false;
    }
    
    func addDest(destBlock:BlockData) -> Bool{
        
        return false;
    }
    
    func updateBlockRect(viewRect:CGRect){
        
    }
    
    func getEffetiveRect() -> CGRect{
        
        return CGRect.zero
    }
    
}