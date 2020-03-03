//
//  StringsListWindowController.swift
//  Strings
//
//  Created by Henry Cooper on 03/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import StringEditorFramework

class StringsListWindowController: NSWindowController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: NSTableView!
    
    // MARK: - Private Properties
    private var stringsFile: StringsFile? {
        return manager.latestStrings
    }
    
    private lazy var displayStrings: [(key: String, value: String)]? = {
        guard let stringsFile = stringsFile else {
            return nil
        }
        return stringsFile.strings.sorted() { $0.key < $1.key }
    }()
    
    private let manager = BitbucketManager.shared
    
    // MARK: - Exposed Properties
    override var windowNibName: NSNib.Name? {
        return "StringsListWindowController"
    }
    
    // MARK: - Initialisation
    init() {
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
    
// MARK: - Table View Data Source
extension StringsListWindowController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return stringsFile?.strings.count ?? 0
    }
    
}

// MARK: - Table View Delegate
extension StringsListWindowController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn, let strings = displayStrings else {
            return nil
        }
        let key = strings[row].key
        let value = strings[row].value
        
        let identifier: String
        let text: String
        
        switch column.identifier {
        case NSUserInterfaceItemIdentifier(rawValue: "KeyColumn"):
            identifier = "KeyView"
            text = key
        case NSUserInterfaceItemIdentifier(rawValue: "ValueColumn"):
            identifier = "ValueView"
            text = value
        default:
            identifier = ""
            text = ""
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(identifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
