//
//  ClipEditViewController.swift
//  TSClipEditor
//
//  Created by Antelis on 21/06/2017.
//  Copyright © 2017 shion. All rights reserved.
//

//
// MARK: - ClipEditViewController: VC for displaying clip thumbnails and handling slider functions
//

import Cocoa

protocol  MultipleRangeSliderDelegate {
    func focusedSliderChanged(start:Float, end:Float, view:Bool)
}
class ClipEditViewController: NSViewController, MultipleRangeSliderDelegate {
    
    var vidInfo:VideoInfoProtocol?
    @IBOutlet weak var clipStartThumb : NSImageView!
    @IBOutlet weak var clipEndThumb : NSImageView!
    @IBOutlet weak var clipSlider : MultipleRangeSlider!
    @IBOutlet weak var playButton : NSButton!
    @IBOutlet weak var addButton : NSButton!
    @IBOutlet weak var tsLocation : NSTextField!
    @IBOutlet weak var discard : NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clipSlider.sliderDelegate = self
        setHint()
    }
    func setHint(){
        let color = NSColor.lightGray
        let font = NSFont.systemFont(ofSize: 14)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedStringKey.foregroundColor: color, NSAttributedStringKey.font: font, NSAttributedStringKey.paragraphStyle: paragraph]
        let placeHolderStr = NSAttributedString(string: "- Please open a TS file to edit clips. -", attributes: attrs)
        tsLocation.alignment = .center
        (tsLocation.cell as! NSTextFieldCell).placeholderAttributedString = placeHolderStr
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
    func setSliderRange(start: Int, end:Int, calibration: Int){
        clipSlider.setSliderRange(start: start, end: end, calibration: calibration)
        self.playButton.isHidden = false
    }
    func addClipSliderThumb(){
        clipSlider.addClipSliderThumb()
        
    }
    func deleteFocusedSliderThumb(){
        clipSlider.deleteFocusedThumb()
    }
    func focusedSliderChanged(start:Float, end:Float, view:Bool){
        vidInfo?.focusedThumbRangeChanged(start: start, end: end, sliderlength: Float(clipSlider.horizontalline.frame.width), view: view)
    }
    func getFocusedSliderRange() -> NSPoint{
        let r = clipSlider.getFocusedClipPortion()
        return r
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
    
    @IBAction func playClip(_ sender: AnyObject!){
        self.vidInfo?.playVideoWithClipRange()
    }
    
    @IBAction func addClipRange(_ sender: AnyObject!){
        self.vidInfo?.addClipThumb()
    }
    
    @IBAction func openTS(_ sender: AnyObject!){
        if let url = NSOpenPanel().selectedFile {
            
            self.tsLocation.stringValue = url.path
            self.vidInfo?.loadVideoWithPath(path: url.path)
            self.addButton.isHidden = false
            self.discard.isHidden = false
        }
    }
    @IBAction func discardCurClip(_ sender: AnyObject!){
        self.discard.resignFirstResponder()
        if dialogOKCancel(question: "Are you sure you want to discard the current clip?", text: "") {
            self.vidInfo?.deleteClipThumb()
        }
        
    }
}
