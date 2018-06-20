//
//  NSOpenPanel-Extension.swift
//  TSClipEditor
//
//  Created by Antelis on 26/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Foundation
import Cocoa

extension NSOpenPanel{
    var selectedFile : URL? {
        allowsMultipleSelection = false
        allowedFileTypes = ["ts","TS"]
        canChooseDirectories = false
        canCreateDirectories = false
        return runModal() == .OK ? urls.first : nil
    }
    var selectedDirectory : URL? {
        allowsMultipleSelection = false
        canChooseDirectories = true
        canCreateDirectories = true
        canChooseFiles = false
        return runModal() == .OK ? urls.first : nil
    }
    
}
