//
//  VideoInfoProtocol.swift
//  TSClipEditor
//
//  Created by Antelis on 2018/6/3.
//  Copyright © 2018 shion. All rights reserved.
//

import Foundation

protocol VideoInfoProtocol {
    //  retrieve video  metadata via ffmpeg
    func loadVideoWithPath(path : String) -> (Int,Int)
    // callback for property to reflect multi-slider operation
    func updateClipThumbRange(index:Int, size:CGSize)
    // Save clip
    func saveClipAtLocation(source : String, dest:String, r:NSPoint)
    // Delete clip
    func deleteClipInfo(_ index: Int)
    //  Range of focused thumb is changed. Notify Property VC.    
    func focusedClipChanged(_ index: Int,_ start: Int,_ end:Int)
    
    func hasFocusedThumb() -> Bool
    
    //func playVideoWithClipRange()
    
    //func collapseClipViewController()
}
