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
    
    // MARK: - Action Methods
    @IBAction func addButtonPressed(_ sender: Any) {
        let newKey = newKeyTextField.stringValue.trimmingCharacters(in: .whitespaces)
        let newValue = newValueTextField.stringValue.trimmingCharacters(in: .whitespaces)
        addToKeysAndValues(key: newKey, value: newValue)
    }
    
    @IBAction func ctaButtonPressed(_ sender: Any) {
        ctaButton.isEnabled = false
        textFieldsAreEnabled(false)
        manager.addToStrings(keysAndValues: newKeysAndValues) { [weak self] (error) in
            DispatchQueue.main.async {
                self?.reset(error: error)
            }
            
        }
    }
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var newKeyTextField: NSTextField!
    @IBOutlet weak var newValueTextField: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var newStringsTableView: NSTableView!
    @IBOutlet weak var ctaButton: NSButton!
    @IBOutlet weak var loadingLabel: NSTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    // MARK: - Private
    private var currentKeysAndValues: KeysAndValues?
    private var newKeysAndValues = KeysAndValues()
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
    
    // MARK: - Life Cycle
    override func windowDidLoad() {
        super.windowDidLoad()
        currentKeysAndValues = manager.latestStrings?.displayTuples
        tableView.reloadData()
        configureButtonStates()
        manager.delegate = self
    }
    
    private func addToKeysAndValues(key: String, value: String) {
        let keys = newKeysAndValues.map() { $0.key }
        if keys.contains(key) {
            loadingLabel.isHidden = false
            loadingLabel.stringValue = "\(key) already in table!"
            return
        }
        let newTuple = (key: key, value: value)
        newKeysAndValues.insert(newTuple, at: 0)
        resetTextFields()
        newStringsTableView.reloadData()
    }

}

// MARK: - UI
extension StringsListWindowController {
    
    private func reset(error: StringEditError?) {
        spinner.isHidden = true
        
        if let error = error {
            loadingLabel.stringValue = error.localizedDescription
        }
        else {
            loadingLabel.stringValue = "Upload successful"
            newKeysAndValues.removeAll()
            newStringsTableView.reloadData()
            tableView.reloadData()
        }
        resetTextFields()
    }
    
    private func resetTextFields() {
        textFieldsAreEnabled(true)
        newValueTextField.stringValue = ""
        newKeyTextField.stringValue = ""
        configureButtonStates()
        newKeyTextField.becomeFirstResponder()
    }
    
    private func textFieldsAreEnabled(_ enabled: Bool) {
        newKeyTextField.isEnabled = enabled
        newValueTextField.isEnabled = enabled
    }
    
    private func configureButtonStates() {
        addButton.isEnabled = !newKeyTextField.stringValue.isEmpty && !newValueTextField.stringValue.isEmpty
        ctaButton.isEnabled = !newKeysAndValues.isEmpty
    }
    
    
}

// MARK: - Table View Data Source
extension StringsListWindowController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.tableView {
            return currentKeysAndValues?.count ?? 0
        }
        else if tableView == newStringsTableView {
            return newKeysAndValues.count
        }
        return 0
    }
    
}

// MARK: - Table View Delegate
extension StringsListWindowController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn, let keysAndValues = correctKeysAndValuesForTableVew(tableView) else {
            return nil
        }
        
        let key = keysAndValues[row].key
        let value = keysAndValues[row].value
        
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
    
    private func correctKeysAndValuesForTableVew(_ tableView: NSTableView) -> KeysAndValues? {
        if tableView == self.tableView {
            return currentKeysAndValues
        }
        else {
            return newKeysAndValues
        }
    }
}

extension StringsListWindowController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        loadingLabel.isHidden = true
        configureButtonStates()
    }
}

extension StringsListWindowController: BitbucketManagerDelegate {
    
    func bitbucketManagerLoadingStateDidChange(_ newState: LoadingState) {
        DispatchQueue.main.async {
            self.updateLabelForLoadingState(newState)
        }
    }
    
    private func updateLabelForLoadingState(_ state: LoadingState) {
        loadingLabel.isHidden = false
        spinner.isHidden = false
        spinner.startAnimation(nil)
        
        switch state {
        case .pulling:
            loadingLabel.stringValue = "Pulling latest changes"
        case .pushing:
            loadingLabel.stringValue = "Pushing your changes"
        }
    }
}
