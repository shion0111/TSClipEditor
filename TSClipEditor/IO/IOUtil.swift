//
//  IOUtil.swift
//  TSClipEditor
//
//  Created by Antelis on 03/07/2017.
//  Copyright © 2017 shion. All rights reserved.
//

// --------------------------------------------------
// MARK: - ClipExporter: Export TS clip in background with Stream
// --------------------------------------------------

import Foundation

public class ClipExporter : NSObject, StreamDelegate {
    
    private var inputstream : InputStream!
    private var outputstream : OutputStream!
    
    //  UI update block
    var progressBlock : ((_ current: Int,_ max: Int) -> Void)?
    //  op finished block
    var finishBlock : ((_ exporter:ClipExporter) -> Void)?
    
    var clipStart : Int = 0
    var clipEnd : Int = 0
    var currentWritten : Int = 0
    
    init(sourcepath: String, destpath: String , start: Int, end: Int){
        self.inputstream = InputStream(fileAtPath: sourcepath)
        self.outputstream = OutputStream(toFileAtPath: destpath, append: false)
        clipStart = start
        clipEnd = end
        
    }
    
    func closeExporter(){
        inputstream.close()
        outputstream.close()
        inputstream = nil
        outputstream = nil
        currentWritten = 0
    }
    
    deinit {
        self.closeExporter()
    }
    
    func saveClip(progress:((_ current: Int,_ max: Int) -> Void)?, finish:((_ exporter:ClipExporter) -> Void)?){
        
        currentWritten = 0
        self.progressBlock = progress
        self.finishBlock = finish
        
        self.inputstream!.delegate = self
        self.inputstream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        //  set file offsest in inputstream
        self.inputstream.setProperty(clipStart , forKey: .fileCurrentOffsetKey)
        self.inputstream!.open()
        
        
        self.outputstream!.delegate = self
        self.outputstream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.outputstream!.open()
        
        let total = self.clipEnd-self.clipStart
        let queue1 = DispatchQueue(label: "com.ioutil.save", qos: DispatchQoS.background)
        queue1.async {
            while self.currentWritten < total {
                
                let buffer = NSMutableData(length:4096)
                let pt = buffer?.mutableBytes.assumingMemoryBound(to: UInt8.self)
                let length = self.inputstream!.read(pt!, maxLength: (buffer?.length)!)
                if 0 < length {
                    
                    self.processData(buffer:buffer!)
                    
                }
            }
            //  exporting finished
            self.finishBlock!(self)
        }
        
    }
    
    @objc func stream(aStream: Stream, handleEvent eventCode: Stream.Event){
        
        switch eventCode {
        case Stream.Event.openCompleted:
            fallthrough
        case Stream.Event.endEncountered:
 
            self.closeExporter()
            self.finishBlock!(self)
            break
        case Stream.Event.errorOccurred:
            NSLog("error")
            break
        case Stream.Event.hasSpaceAvailable:
            NSLog("HasSpaceAvailable")
            break
        case Stream.Event.hasBytesAvailable:
            NSLog("HasBytesAvaible")
            
            
            break
        default:
            break
        }
    }
    
    //  write data from inputstream to outputstream
    func processData(buffer: NSMutableData) {
        let pt = buffer.mutableBytes.assumingMemoryBound(to: UInt8.self)
        let l = self.outputstream.write(pt, maxLength: buffer.length)
        currentWritten += l
        self.progressBlock!(currentWritten,clipEnd-clipStart)
    }
}
