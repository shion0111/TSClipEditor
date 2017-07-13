//
//  ThumbRangeInfoViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 13/07/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Foundation
protocol ClipInfoDelegate {
    func discardTheThumb()
    func saveClipWithDestDirectory(destdir:String)
}

class ThumbRangeInfoViewController: NSViewController {
    
    var infoDelegate:ClipInfoDelegate?
    
    @IBOutlet weak var rangeStart: NSTextField!
    @IBOutlet weak var rangeEnd: NSTextField!
    @IBOutlet weak var destLocation: NSTextField!
    @IBOutlet weak var discard : NSButton!
    @IBOutlet weak var saveone : NSButton!
    @IBOutlet weak var saveprogress : NSProgressIndicator!
    @IBOutlet weak var savebox: NSBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        self.view.wantsLayer = true
        let colorTop = NSColor(red: 236 / 255, green: 240 / 255, blue: 250 / 241, alpha: 0.6).cgColor
        let color2 = NSColor(red: 255 / 255, green: 248 / 255, blue: 225 / 255, alpha: 0.6).cgColor
        let colorBottom = NSColor(red: 236 / 255, green: 239 / 255, blue: 241 / 255, alpha: 0.6).cgColor
        let gradient  = CAGradientLayer()
        gradient.colors = [ color2, colorBottom,colorTop]
        gradient.locations = [ 0.0,0.8, 1.0]
        gradient.cornerRadius = 16
        gradient.borderColor = color2
        gradient.borderWidth = 1
        self.view.layer = gradient
         */
    }
    
    @IBAction func discardCurClip(_ sender: AnyObject!){
        self.infoDelegate?.discardTheThumb()
    }
    
    @IBAction func saveCurClip(_ sender: AnyObject!){
        
        /*if !(vidInfo!.hasFocusedThumb()) {
            return
        }
        */
        if let url = NSOpenPanel().selectedDirectory {
            
            self.destLocation.stringValue = url.path
            print("Selected directories: (\(url.path))")
            self.savebox.isHidden = false
            self.infoDelegate?.saveClipWithDestDirectory(destdir: url.path)
            self.saveprogress.startAnimation(nil)
        }
    }
  
    
    func updateSaveProgress(increment: Int, max:Int){
        if saveprogress.doubleValue < 1 {
            saveprogress.maxValue = Double(max)
        }
        
        saveprogress.increment(by: Double(increment) - saveprogress.doubleValue)
        
    }
    func clipRangeChanged(start: Float, end: Float){
        self.rangeStart.stringValue = String(start)
        self.rangeEnd.stringValue = String(end)
    }
    func finishSaveProgress(){
        saveprogress.stopAnimation(nil)
        print("save finish!!")
        savebox.isHidden = true
    }
    /*
     override func viewDidMoveToWindow() {
     
     guard let frameView = window?.contentView?.superview else {
     return
     }
     
     let backgroundView = NSView(frame: frameView.bounds)
     backgroundView.wantsLayer = true
     backgroundView.layer?.backgroundColor = .white // colour of your choice
     backgroundView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
     
     frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
     
     }
     */
}
