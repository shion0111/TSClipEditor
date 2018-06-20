//
//  EditorViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 2018/6/3.
//  Copyright © 2018 shion. All rights reserved.
//

import Cocoa
class ClipRowView : NSTableRowView {
    @IBOutlet var startLabel : NSTextField?
    @IBOutlet var endLabel : NSTextField?
    
    
    override func drawSelection(in dirtyRect: NSRect) {
        NSColor.selectedControlColor.setFill()
        let rect = NSRect(x: dirtyRect.origin.x+3, y: dirtyRect.origin.y+2, width: dirtyRect.size.width-6, height: dirtyRect.size.height-4)
        
        let path: NSBezierPath = NSBezierPath(roundedRect: rect, xRadius: 5.0, yRadius: 5.0)
        path.addClip()
        path.fill()
    }
    
    override func drawBackground(in dirtyRect: NSRect) {
        NSColor.secondarySelectedControlColor.setFill()
        let rect = NSRect(x: dirtyRect.origin.x+3, y: dirtyRect.origin.y+2, width: dirtyRect.size.width-6, height: dirtyRect.size.height-4)
        
        let path: NSBezierPath = NSBezierPath(roundedRect: rect, xRadius: 5.0, yRadius: 5.0)
        path.addClip()
        path.fill()
    }
}
//MARK: -
class EditorViewController: NSViewController,MultipleRangeSliderDelegate,NSPopoverDelegate,NSTableViewDelegate,NSTableViewDataSource {
    
    
    private var videoInfo : VideoInfo?
    
    @IBOutlet var tapLabel : NSTextField?
    
    @IBOutlet  var clipStartThumb : NSImageView!
    @IBOutlet  var clipEndThumb : NSImageView!
    @IBOutlet  var clipSlider : MultipleRangeSlider!
    @IBOutlet  var exportButton : NSButton!
    @IBOutlet  var addButton : NSButton!
    @IBOutlet  var discard : NSButton!
    @IBOutlet  var clipList: NSTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let la = self.tapLabel {
            
            let c = NSClickGestureRecognizer(target: self, action: #selector(tapToOpen))
            la.addGestureRecognizer(c)
        }
        clipSlider.setSliderRange(start: 0, end: 1, calibration: 1)
        clipSlider.sliderDelegate = self
        self.videoInfo = VideoInfo()
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @objc private func tapToOpen(_ sender : Any?) {
        
        self.openTS(sender)
        
    }
    
    @IBAction func openTS(_ sender: Any?){
        if let url = NSOpenPanel().selectedFile {
            self.tapLabel?.isHidden = true
            self.addButton.isEnabled = true
            self.discard.isEnabled = true
            if let vi = self.videoInfo {
                let (duration, st) = vi.loadVideoWithPath(path: url.path)
                self.clipSlider.setSliderRange(start: 0, end: duration, calibration: st)
                
            }
        }
    }
    
    func setThumbnailImage(image : CGImage, isEnd: Bool){
        
        if isEnd {
            self.clipEndThumb.image = nil
            self.clipEndThumb.image = NSImage(cgImage: image, size: self.clipEndThumb.frame.size)
        } else {
            self.clipStartThumb.image = nil
            self.clipStartThumb.image = NSImage(cgImage: image, size: self.clipStartThumb.frame.size)
        }
    }
    
    func focusedSliderChanged(focused:AnyObject?, start: Float, end: Float, view: Bool) {
        
        if let vi = self.videoInfo {
            let w = (Int)(self.clipSlider.frame.width)
            let s = start*Float(vi.tsduration/w)
            let e = end*Float(vi.tsduration/w)
            
            let se = self.clipList.selectedRow
            if se >= 0 {
                
                vi.focusedClipChanged(self.clipList.selectedRow,Int(s),Int(e))
                self.clipList.reloadData()
                self.clipList.selectRowIndexes(IndexSet(integer: se), byExtendingSelection: false)
            }
            
            self.loadFramesWithRange(Int(s), Int(e))
        }
    }
    func loadFramesWithRange(_ start: Int, _ end: Int) {
        if let vi = self.videoInfo {
            if let cgimage = vi.loadVideoThumbnails(tick: start, isEnd: false) {
                setThumbnailImage(image: cgimage, isEnd: false)
            }
            
            
            unowned let unownedSelf = self
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                if let vi = unownedSelf.videoInfo {
                    
                    if let cgimage = vi.loadVideoThumbnails(tick: end, isEnd: true) {
                        unownedSelf.setThumbnailImage(image: cgimage, isEnd: true)
                    }
                }
            })
        }
        
        
    }
    
    func discardTheThumb() {
        
    }
    private func getClipNameWithTick() -> String{
        
        let tick = llround(Date().timeIntervalSince1970)
        return String(format: "TSClip_%lld.ts", tick)
        
    }
    func saveClipWithDestDirectory(destdir: String) {
        let url = URL(fileURLWithPath: destdir)
        let fname = getClipNameWithTick()
//        let dest = url.appendingPathComponent(fname)
//        let info = popover.contentViewController as! ThumbRangeInfoViewController
//        info.destLocation.stringValue = dest.path
//        //  get clip range
//        let r = getFocusedSliderRange()
//        self.vidInfo?.saveClipAtLocation(source: self.tsLocation.stringValue, dest: dest.path, r:r)
    }
    
    @IBAction func appendClipInfo(_ sender: Any?) {
        if let vi = videoInfo {
            vi.addClipInfo(1, 20)
            self.clipList.reloadData()
        }
    }
    @IBAction func delClipInfo(_ sender: Any?) {
        if let vi = videoInfo , self.clipList.selectedRow >= 0{
            vi.deleteClipInfo(self.clipList.selectedRow)
            self.clipList.selectRowIndexes(IndexSet(), byExtendingSelection: false)
            self.clipList.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let vi = videoInfo {
            return vi.clips.count
        }
        return 0
    }
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        
        let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ClipRowView"), owner: nil) as? ClipRowView
        
        if let rv = rowView,let vi = videoInfo {
            let info = vi.clips[row]
            rv.startLabel?.stringValue = "\(info.start) secs"
            rv.endLabel?.stringValue = "\(info.end) secs"
            
        }

        return rowView;
        

    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = self.clipList.selectedRow
        if row >= 0 ,let vi = videoInfo {
            let info = vi.clips[row]
            self.clipSlider.updateFocusedPosition(info.start, info.end)
            
            
        }
    }
    
}

