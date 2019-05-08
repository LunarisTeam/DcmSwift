//
//  SidebarViewController.swift
//  MagiX
//
//  Created by Rafael Warnault on 28/04/2019.
//  Copyright © 2019 Read-Write.fr. All rights reserved.
//

import Cocoa
import CoreData
import DcmSwift

let directoryPastebaodrType = NSPasteboard.PasteboardType(rawValue: "pro.opale.MagiX.sidebar.directory")

class SidebarViewController:    NSViewController,
                                NSTableViewDataSource,
                                NSTableViewDelegate,
                                NSOutlineViewDelegate,
                                NSOutlineViewDataSource {
    
    @IBOutlet weak var directoriesOutlineView: NSOutlineView!
    @IBOutlet weak var operationsTableView: NSTableView!
    
    var categories:[String] = ["DIRECTORIES", "REMOTES"]
    var directories:[Directory] = []
    var remotes:[Remote] = []
    var draggedNode:AnyObject? = nil
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadOperationChanged(n:)), name: .loadOperationStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadOperationChanged(n:)), name: .loadOperationFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadOperationChanged(n:)), name: .loadOperationCancelled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadOperationChanged(n:)), name: .loadOperationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateRemote(n:)), name: .didUpdateRemote, object: nil)
        
        self.directories = DataController.shared.fetchDirectories()
        self.remotes = DataController.shared.fetchRemotes()
        
        self.reloadRemotesStatus()
        _ = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { timer in
            self.reloadRemotesStatus()
        }
        
        // drag and drop
        // Register for the dropped object types we can accept.
        self.directoriesOutlineView.registerForDraggedTypes([directoryPastebaodrType, dataPastebaodrType])
        
        // Disable dragging items from our view to other applications.
        //self.directoriesOutlineView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
        // Enable dragging items within and into our view.
        self.directoriesOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        
        self.directoriesOutlineView.reloadData()
        self.directoriesOutlineView.expandItem(self.directoriesOutlineView.item(atRow: 1), expandChildren: true)
        self.directoriesOutlineView.expandItem(self.directoriesOutlineView.item(atRow: 0), expandChildren: true)
        
        self.directoriesOutlineView.target = self
        self.directoriesOutlineView.doubleAction = #selector(directoriesOutlineViewDoubleClick(s:))
    }
    
    
    
    
    
    // MARK: - Notification
    
    @objc func loadOperationChanged(n:Notification) {
        self.operationsTableView.reloadData()
    }
    
    
    
    @objc func didUpdateRemote(n:Notification) {
        self.remotes = DataController.shared.fetchRemotes()
        self.directoriesOutlineView.reloadData()
    }
    
    
    
    @objc func directoriesOutlineViewDoubleClick(s:Any) {
        if let selectedItem = self.directoriesOutlineView.item(atRow: self.directoriesOutlineView.clickedRow) as? Remote {
            if let remoteVC:RemoteEditViewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "RemoteEditViewController") as? RemoteEditViewController {
                remoteVC.remote = selectedItem
                self.presentAsSheet(remoteVC)
            }
        }
    }
    
    
    // MARK: - IBAction
    
    @IBAction func newDirectory(_ sender: Any) {
        let newDirectory = PrivateDirectory(context: DataController.shared.context)
        newDirectory.name = "New Directory \(directories.count)"
        
        DataController.shared.save()
        
        self.directories.append(newDirectory)
        self.directoriesOutlineView.reloadData()
    }
    
    @IBAction func newSmartDirectory(_ sender: Any) {
        let newDirectory = SmartDirectory(context: DataController.shared.context)
        newDirectory.name = "New Directory \(directories.count)"
        
        DataController.shared.save()
        
        self.directories.append(newDirectory)
        self.directoriesOutlineView.reloadData()
    }
    
    @IBAction func newRemote(_ sender: Any) {
        if let remoteVC:NSViewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "RemoteEditViewController") as? RemoteEditViewController {
            self.presentAsSheet(remoteVC)
        }
    }
    
    @IBAction func remove(_ sender: Any) {
        let selectedItem = self.directoriesOutlineView.item(atRow: self.directoriesOutlineView.selectedRow)
        
        if let d = selectedItem as? PrivateDirectory {
            DataController.shared.removeDirectory(d)
            
            if let index = self.directories.index(of:d) {
                self.directories.remove(at: index)
            }
        }
        else if let r = selectedItem as? Remote {
            DataController.shared.removeRemote(r)
            
            if let index = self.remotes.index(of:r) {
                self.remotes.remove(at: index)
            }
        }
        
        self.directoriesOutlineView.reloadData()
    }
    
    
    
    // MARK: - Outline View
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return self.categories.count
        } else {
            if (item as! String) == self.categories.first {
                return self.directories.count
            }
            else if (item as! String) == self.categories.last {
                return self.remotes.count
            }
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let headerItem = item as? String {
            if headerItem == self.categories.first {
                return self.directories[index]
            }
            else if headerItem == self.categories.last {
                return self.remotes[index]
            }
        }
        
        return self.categories[index]
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return ((item as? String) != nil) ? true : false
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return ((item as? String) != nil) ? false : true
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        if let headerItem = item as? String {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as? NSTableCellView
            view?.textField?.stringValue = headerItem
        }
        else if let directory = item as? Directory {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView

            if item is PrivateDirectory {
                view?.imageView?.image = NSImage(named: NSImage.Name("NSFolder"))
            }
            else if item is SmartDirectory {
                view?.imageView?.image = NSImage(named: NSImage.Name("NSFolderSmart"))
            }
            view?.textField?.stringValue = directory.name ?? "NO NAME"
        }
        else if let remote = item as? Remote {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView

            if remote.status == 0 {
                view?.imageView?.image = NSImage(named: NSImage.Name("NSStatusNone"))
            }
            else if remote.status == 1 {
                view?.imageView?.image = NSImage(named: NSImage.Name("NSStatusAvailable"))
            }
            else if remote.status == 2 {
                view?.imageView?.image = NSImage(named: NSImage.Name("NSStatusUnavailable"))
            }
            view?.textField?.stringValue = remote.name ?? "NO NAME"
        }
        
        return view
    }
    
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let selectedItem = self.directoriesOutlineView.item(atRow: self.directoriesOutlineView.selectedRow) {
            // select appropriated tab
            if let tabViewController = (self.parent as? NSSplitViewController)?.splitViewItems[1].viewController as? NSTabViewController {
                if let directory = selectedItem as? Directory {
                    tabViewController.tabView.selectTabViewItem(at: 0)
                                        
                    if let svc = tabViewController.tabView.selectedTabViewItem?.viewController as? NSSplitViewController {
                        if let svc2 = svc.children[0] as? NSSplitViewController {
                            if let vc = svc2.children[0] as? DataViewController {
                                vc.representedObject = directory
                            }
                        }
                        
                    }
                }
                else if let remote = selectedItem as? Remote {
                    tabViewController.tabView.selectTabViewItem(at: 1)
                    
                    if let svc = tabViewController.tabView.selectedTabViewItem?.viewController as? NSSplitViewController {
                        if let remoteViewController = svc.children[0] as? RemoteViewController {
                            remoteViewController.representedObject = remote
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: NSOutlineView Drag & Drop
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        var retVal:NSDragOperation = NSDragOperation()
        
        if (item as? PrivateDirectory) != nil {
            retVal = NSDragOperation.copy
        }

        return retVal
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        var retVal:Bool = false
        
        if let data = info.draggingPasteboard.data(forType: dataPastebaodrType) {
            if let objectIDs = NSKeyedUnarchiver.unarchiveObject(with: data) as? [URL] {
                for objectID in objectIDs {
                    if let managedObjectID = DataController.shared.context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectID) {
                        if let study = DataController.shared.context.object(with: managedObjectID) as? Study {
                            if let privateDirectory = item as? PrivateDirectory {
                                privateDirectory.addToStudies(study)
                                retVal = true
                            }
                        }
                    }
                }
            }
        }
        return retVal
    }
    

    
    // MARK: - Table View
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return DataController.shared.operationQueue.operations.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: OperationCellView?
        
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "OperationCellView"), owner: self) as? OperationCellView
        
        if let laodOperation = DataController.shared.operationQueue.operations[row] as? LoadOperation {
            view?.textField?.stringValue = "Load files: \(laodOperation.currentIndex)/\(laodOperation.numberOfFiles)"
            view?.progressBar.doubleValue = Double(laodOperation.percents)
        }
        
        return view
    }
    
    
    
    
    // MARK: - Private
    
    private func reloadRemotesStatus() {
        for r in self.remotes {
            let localAET = UserDefaults.standard.string(forKey: "LocalAET")!
            let callingAE = DicomEntity(title: localAET, hostname: "127.0.0.1", port: 11112)
            if let calledAE = r.dicomEntity {
                let client = DicomClient(localEntity: callingAE, remoteEntity: calledAE)
                
                client.connect { (ok, error) in
                    if ok {
                        client.echo() { (okEcho, receivedMessage, errorEcho) in
                            if okEcho {
                                r.status = 1
                            } else {
                                r.status = 2
                            }
                            DataController.shared.save()
                            self.remotes = DataController.shared.fetchRemotes()
                            self.directoriesOutlineView.reloadData()
                        }
                    } else {
                        r.status = 2
                        
                        DataController.shared.save()
                        self.remotes = DataController.shared.fetchRemotes()
                        self.directoriesOutlineView.reloadData()
                    }
                }
            }
        }
    }
}
