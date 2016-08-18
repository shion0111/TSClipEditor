//
//  BlockView.swift
//  BlockGraphEditor
//
//  Created by Antelis on 2016/7/22.

//

import Cocoa

extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    /// Returns a png representation of the current image.
    var PNGRepresentation: NSData? {
        if let tiff = self.TIFFRepresentation, tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representationUsingType(.NSPNGFileType, properties: [:])
        }
        
        return nil
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copyWithSize(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentationForRect(frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.drawInRect(frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copyWithSize(newSize)
    }
    
    ///  Copies and crops an image to the supplied size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The cropped copy of the given image.
    func cropToSize(size: NSSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatioToSize(size) else {
            return nil
        }
        // Get some points to center the cropping area.
        let x = floor((resized.width - size.width) / 2)
        let y = floor((resized.height - size.height) / 2)
        
        // Create the cropping frame.
        let frame = NSMakeRect(x, y, size.width, size.height)
        
        // Get the best representation of the image for the given cropping frame.
        guard let rep = resized.bestRepresentationForRect(frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a new image with the new size
        let img = NSImage(size: size)
        
        img.lockFocus()
        defer { img.unlockFocus() }
        
        if rep.drawInRect(NSMakeRect(0, 0, size.width, size.height),
                          fromRect: frame,
                          operation: NSCompositingOperation.CompositeCopy,
                          fraction: 1.0,
                          respectFlipped: false,
                          hints: [:]) {
            // Return the cropped image.
            return img
        }
        
        // Return nil in case anything fails.
        return nil
    }
    
    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: NSURL) throws {
        if let png = self.PNGRepresentation {
            try png.writeToURL(url, options: .AtomicWrite)
        }
    }
}

class DragAndDropImageView : NSImageView, NSDraggingSource{
    
    var mouseDownEvent : NSEvent?
    
    override init(frame frameRect: NSRect){
        super.init(frame: frameRect)
        
        self.editable = true
    }
    
    required init?(coder:NSCoder){
        super.init(coder:coder)
        
        self.editable = true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
        super.drawRect(dirtyRect)
    }
    
    

    func draggingSession(session: NSDraggingSession, sourceOperationMaskForDraggingContext context: NSDraggingContext) -> NSDragOperation{
        return [.Copy, .Delete]
    }
 
    func draggingSession(session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        
        if operation == .Delete{
            self.image = nil
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        
        self.mouseDownEvent = theEvent
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        
        let mouseDown = self.mouseDownEvent!.locationInWindow
        let dragPoint = theEvent.locationInWindow
        let dragDistance = hypot(mouseDown.x - dragPoint.x, mouseDown.y-dragPoint.y)
        
        if dragDistance < 3 {
            return
        }
        
        if let image = self.image{
            // Do some math to properly resize the given image.
            let size = NSSize(width: log10(image.size.width) * 30, height: log10(image.size.height) * 30)
            let img  = image.copyWithSize(size)!
            
            // Create a new NSDraggingItem with the image as content.
            let draggingItem        = NSDraggingItem(pasteboardWriter: image)
            // Calculate the mouseDown location from the window's coordinate system to the
            // ImageView's coordinate system, to use it as origin for the dragging frame.
            let draggingFrameOrigin = convertPoint(mouseDown, fromView: nil)
            // Build the dragging frame and offset it by half the image size on each axis
            // to center the mouse cursor within the dragging frame.
            let draggingFrame       = NSRect(origin: draggingFrameOrigin, size: img.size).offsetBy(dx: -img.size.width / 2, dy: -img.size.height / 2)
            
            // Assign the dragging frame to the draggingFrame property of our dragging item.
            draggingItem.draggingFrame = draggingFrame
            
            // Provide the components of the dragging image.
            draggingItem.imageComponentsProvider = {
                let component = NSDraggingImageComponent(key: NSDraggingImageComponentIconKey)
                
                component.contents = image
                component.frame    = NSRect(origin: NSPoint(), size: draggingFrame.size)
                return [component]
            }
            
            // Begin actual dragging session. Woohow!
            beginDraggingSessionWithItems([draggingItem], event: mouseDownEvent!, source: self)
        }
    }
    
}

class BlockView: DragAndDropImageView {

    var data:BlockData
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    
    
    required init(frame: NSRect, dtype:Int32){
    
        data = BlockData(dataType: dtype)
        super.init(frame:frame)
        
        
        
    }
    
    required init?(coder: NSCoder) {
        data = BlockData(dataType: 0)
        super.init(coder: coder)
    }
    
    
}
