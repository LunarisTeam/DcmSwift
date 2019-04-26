//
//  InspectorViewController.swift
//  DicomiX
//
//  Created by Rafael Warnault on 25/10/2017.
//  Copyright © 2017 OPALE, Rafaël Warnault. All rights reserved.
//

import Cocoa
import DcmSwift


class InspectorViewController: NSViewController {
    @IBOutlet var myStackView: NSStackView!
    
    public var dicomFile:DicomFile!
    
    var oldSelection: Int = 0
    var newSelection: Int = 0
    
    var buttons: [NSButton]?
    var tabViewDelegate: NSTabViewController?

    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        buttons = (myStackView.arrangedSubviews as! [NSButton])
    }
    
    
    override var representedObject: Any? {
        didSet {
            if let document:DicomDocument = representedObject as? DicomDocument {
                self.dicomFile = document.dicomFile
                
                for vc in (tabViewDelegate?.children)! {
                    let _ = vc.view // needed to preload views and outlets !!!                    
                    vc.representedObject = document
                }
            }
        }
    }
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        // Once on load
        tabViewDelegate = segue.destinationController as?  NSTabViewController
    }
    
    
    
    // MARK: - IBAction
    @IBAction func selectedButton(_ sender: NSButton) {
        newSelection = sender.tag
        tabViewDelegate?.selectedTabViewItemIndex = newSelection
        
        buttons![oldSelection].state = .off
        sender.state = .on
        
        oldSelection = newSelection
    }
    
}
