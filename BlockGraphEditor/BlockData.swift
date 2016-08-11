//
//  BlockData.swift
//  BlockGraphEditor
//
//  Created by Antelis on 2016/7/22.

//

import Foundation
import AppKit

class BlockData{
    
    var type: Int32 = 0
    
    var blockUID:NSUUID
    
    var source = [BlockData]()
    var dest = [BlockData]()
    
    var blockRect:CGRect = CGRect.zero  //default rect is retrieved from fieldManager
    
    init(dataType:Int32) {
        
        type = dataType
        blockUID = NSUUID()
    }
    
    func addSource(sourceBlock:BlockData) -> Bool {
            
        let index = source.indexOf{ $0.blockUID == sourceBlock.blockUID}
        if index >= 0 {
            return true
        }
        
        source.append(sourceBlock)
        
        return true
    }
    
    func addDest(destBlock:BlockData) -> Bool{
        
        let index = dest.indexOf{ $0.blockUID == destBlock.blockUID}
        if index >= 0 {
            return true
        }
        
        dest.append(destBlock)
        
        return true

    }
    
    func updateBlockRect(viewRect:CGRect){
        
    }
    
    func getEffetiveRect() -> CGRect{
        
        return CGRect.zero
    }
    
}