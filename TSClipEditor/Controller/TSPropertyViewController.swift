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
    @IBOutlet weak var discard : NSButton!
    @IBOutlet weak var saveone : NSButton!
    @IBOutlet weak var saveprogress : NSProgressIndicator!
    
    public var vidInfo: VideoInfoProtocol?
    
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
    func clipRangeChanged(start: Float, end: Float){
        self.rangeStart.stringValue = String(start)
        self.rangeEnd.stringValue = String(end)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    func updateSaveProgress(increment: Int, max:Int){
        if saveprogress.doubleValue < 1 {
            saveprogress.maxValue = Double(max)
        }
        
        saveprogress.increment(by: Double(increment) - saveprogress.doubleValue)
        
    }
    func finishSaveProgress(){
        saveprogress.stopAnimation(nil)
        print("save finish!!")
        saveprogress.isHidden = true
    }
    
    @IBAction func openTS(_ sender: AnyObject!){
        
        if let url = NSOpenPanel().selectedFile {
            
            self.tsLocation.stringValue = url.path
            _tsduration = (self.vidInfo?.loadVideoWithPath(path: url.path))!//Int(getVideoDurationWithLoc(url.path))
            self.duration.stringValue = String(_tsduration)
            //self.rangeStart.stringValue = "0"
            //self.rangeEnd.stringValue = String(_tsduration)
            self.discard.isEnabled = true
            self.saveone.isEnabled = true
        }
        
    }
    
    @IBAction func addClipRange(_ sender: AnyObject!){
        self.vidInfo?.addClipThumb()
    }
    
    @IBAction func discardCurClip(_ sender: AnyObject!){
        self.discard.resignFirstResponder()
        if dialogOKCancel(question: "Are you sure you want to discard the current clip?", text: "") {
            self.vidInfo?.deleteClipThumb()
        }
        
    }
    @IBAction func saveCurClip(_ sender: AnyObject!){
        
        if !(vidInfo!.hasFocusedThumb()) {
            return
        }
        
        if let url = NSOpenPanel().selectedDirectory {
            
            self.destLocation.stringValue = url.path
            print("Selected directories: (\(url.path))")
            let fname = getClipNameWithTick()
            let dest = url.appendingPathComponent(fname)
            self.destLocation.stringValue = dest.path
            self.saveprogress.isHidden = false
            self.saveprogress.startAnimation(nil)
            self.vidInfo?.saveClipAtLocation(source: self.tsLocation.stringValue, dest: dest.path)
        }
    }
    @IBAction func saveAllClips(_ sender: AnyObject!){
        
    }
    
}
