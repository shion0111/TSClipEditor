//
//  TSPropertyViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 26/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Cocoa


class TSPropertyViewController: NSViewController {
    
    @IBOutlet weak var tsLocation : NSTextField!
    @IBOutlet weak var duration : NSTextField!
    @IBOutlet weak var rangeStart: NSTextField!
    @IBOutlet weak var rangeEnd: NSTextField!
    @IBOutlet weak var destLocation: NSTextField!
    
    public var vidInfo: VideoInfoProtocol!
    
    private var _tsduration : Int = 0
    
    public var tsDuration: Int {
        get { return _tsduration }
        set { _tsduration = newValue }
    }
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let i = segue.identifier{
            print("TSPropertyViewController",i)
            print(sender.debugDescription)
            
        }
        
    }
    
    func getClipNameWithTick() -> String{
        
        let tick = llround(Date().timeIntervalSince1970)
        return String(format: "TSClip_%lld.ts", tick)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    @IBAction func openTS(_ sender: AnyObject!){
        
        if let url = NSOpenPanel().selectedFile {
            
            self.tsLocation.stringValue = url.path
            _tsduration = self.vidInfo.loadVideoWithPath(path: url.path)//Int(getVideoDurationWithLoc(url.path))
            self.duration.stringValue = String(_tsduration)
            self.rangeStart.stringValue = "0"
            self.rangeEnd.stringValue = String(_tsduration)
        }
        
    }
    
    @IBAction func addClipRange(_ sender: AnyObject!){
        let newrange = self.vidInfo.addClipThumb()
        
        self.rangeStart.stringValue = String(newrange.lowerBound)
        self.rangeEnd.stringValue = String(newrange.upperBound)
    }
    @IBAction func deleteCurClip(_ sender: AnyObject!){
        
    }
    @IBAction func saveCurClip(_ sender: AnyObject!){
        if let url = NSOpenPanel().selectedDirectory {
            
            self.destLocation.stringValue = url.path
            print("Selected directories: (\(url.path))")
            let fname = getClipNameWithTick()
            let dest = url.appendingPathComponent(fname)
            self.destLocation.stringValue = dest.path
        }
    }
    @IBAction func saveAllClips(_ sender: AnyObject!){
        
    }
    
}
