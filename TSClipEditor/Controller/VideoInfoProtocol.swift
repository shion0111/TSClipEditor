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
    // Save clip
    func saveSelectedClipAtLocation(dest:String, d:ClipInfo)
    // Delete clip
    func deleteClipInfo(_ index: Int)
    //  Range of focused thumb is changed. Notify Property VC.    
    func focusedClipChanged(_ start: Int,_ end:Int)
    
}
protocol ProgressInfoProtocol {
    func progressUpdated(_ cur: Int, _ max: Int, _ finished:Bool)
}
