//
//  ViewController.swift
//  BlockGraphEditor
//
//  Created by Antelis on 2016/7/22.

//

import Cocoa

class headerItem : NSView{
    
    var headerTitle: NSTextField?
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
}

class ViewController: NSViewController,NSCollectionViewDelegate,NSCollectionViewDataSource {

    @IBOutlet weak var blockItemList: NSCollectionView!

    //IBOutlet NSCollectionView
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //[self.collectionView registerClass:[NSCollectionViewItem class] forItemWithIdentifier:@"BlockItemCell"]
        
        let nib = NSNib(nibNamed: "BlockItemCell", bundle: nil)
        blockItemList.registerNib(nib, forItemWithIdentifier: "BlockItemCell")
        
        blockItemList.registerClass(headerItem.self, forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader, withIdentifier: "ListHeader")
        
        //blockItemList.backgroundView?.wantsLayer = true
        //blockItemList.backgroundColors = [NSColor.clearColor()]
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func collectionView(collectionView: NSCollectionView, willDisplaySupplementaryView view: NSView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath){
    
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int{
        return 2
    }
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int{
        
        if section == 0 {
            return 2
        }
        
        return 1
    }
    
    
    
    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem{

        let item = collectionView.makeItemWithIdentifier("BlockItemCell", forIndexPath: indexPath)
        
        item.view.wantsLayer = true
        item.view.layer?.backgroundColor = NSColor.clearColor().CGColor
        
        //item.textField?.stringValue = n
        
        item.view.layer?.cornerRadius = 2.0
        
        return item

    }
}
