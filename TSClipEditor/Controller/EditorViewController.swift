//
//  EditorViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 2018/6/3.
//  Copyright © 2018 shion. All rights reserved.
//

import Cocoa
//
class ClipRowView : NSTableRowView,ProgressInfoProtocol {
    @IBOutlet var startLabel : NSTextField?
    @IBOutlet var endLabel : NSTextField?
    @IBOutlet var progress : NSProgressIndicator?
    @IBOutlet var save : NSButton?
    
    override func drawBackground(in dirtyRect: NSRect) {
        NSColor.secondarySelectedControlColor.setFill()
        let rect = NSRect(x: dirtyRect.origin.x+3, y: dirtyRect.origin.y+2, width: dirtyRect.size.width-6, height: dirtyRect.size.height-4)
        let path: NSBezierPath = NSBezierPath(roundedRect: rect, xRadius: 5.0, yRadius: 5.0)
        path.addClip()
        path.fill()
    }
    
    override var isSelected: Bool {
        willSet(newValue) {
            super.isSelected = newValue;
            needsDisplay = true
            
            progress?.isHidden = !newValue
            save?.isHidden = !newValue
            
        }
    }
    
    func progressUpdated(_ cur: Int, _ max: Int, _ finished:Bool) {
        if let p = self.progress {
            if !finished {
                p.maxValue = Double(max)
                p.minValue = 0
                p.doubleValue = Double(cur)
            } else {
            
            }
        }
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
        clipSlider.setSliderRange(start: 0, end: 0, calibration: 10)
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
    
    @IBAction func saveTS(_ sender: Any?){
        
        if let url = NSOpenPanel().selectedDirectory {
            self.saveClipWithDestDirectory(destdir: url.path)
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
            
            //let se = //self.clipList.selectedRow
            //if se >= 0 {
                
                vi.focusedClipChanged(Int(s),Int(e))
                self.clipList.reloadData()
                //self.clipList.selectRowIndexes(IndexSet(integer: se), byExtendingSelection: false)
            //}
            
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
        let dest = url.appendingPathComponent(fname)
        //  get clip range
        
        if let vi = videoInfo, let info = vi.getFocusedClip() {
            vi.saveSelectedClipAtLocation(dest: dest.path, r: info.duration)
        }
    }
    
    @IBAction func appendClipInfo(_ sender: Any?) {
        if let vi = videoInfo {
            
            vi.addClipInfo(1, vi.tsduration/20)
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
            return vi.getClipsCount()
        }
        return 0
    }
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        
        let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ClipRowView"), owner: nil) as? ClipRowView
        
        if let rv = rowView,let vi = videoInfo {
            if let info = vi.getClipWithIndex(row) {
                rv.selectionHighlightStyle = .none
                rv.startLabel?.stringValue = "\(info.duration.start) secs"
                rv.endLabel?.stringValue = "\(info.duration.end) secs"
                if info.isfocused {
                    rv.isSelected = true
                    rv.selectionHighlightStyle = .regular
                    vi.progress = rv
                }
            }
        }

        return rowView;    
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = self.clipList.selectedRow
        if row >= 0 ,let vi = videoInfo {
            //  get selected ClipRowView
            if let rv = self.clipList.rowView(atRow: row, makeIfNecessary: false) as? ClipRowView {
                vi.progress = rv
            }
            
            vi.setFocusedClip(row)
            if let info = vi.getFocusedClip() {
                self.clipSlider.updateFocusedPosition(info.duration.start, info.duration.end)
                self.loadFramesWithRange(info.duration.start, info.duration.end)
            }
        }
    }
    
}

