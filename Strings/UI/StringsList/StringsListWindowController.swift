//
//  StringsListWindowController.swift
//  Strings
//
//  Created by Henry Cooper on 03/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import UIHelper
import StringEditorFramework


class StringsListWindowController: NSWindowController {
    
    // MARK: - Action Methods
    @IBAction func addButtonPressed(_ sender: Any) {
        let newKey = newKeyTextField.stringValue.trimmingCharacters(in: .whitespaces)
        let newValue = newValueTextField.stringValue.trimmingCharacters(in: .whitespaces)
        addToKeysAndValues(key: newKey, value: newValue)
    }
    
    @IBAction func ctaButtonPressed(_ sender: Any) {
        enableInterface(false)
        // Manually disable so we can't spam
        ctaButton.isEnabled = false
        manager.addToStrings(keysAndValues: newKeysAndValuesToAdd, editedStrings: editedStrings) { [weak self] (error) in
            DispatchQueue.main.async {
                self?.reset(error: error)
            }
        }
    }
    
    @IBAction func radioButtonSelected(_ sender: NSButton) {
        guard sender != selectedButton else {
            return
        }
        selectedButton = sender
        let newPlatform: Platform = (sender == iosButton) ? .ios : .android
        BitbucketManager.shared.changePlatformTo(newPlatform) { (error) in
            DispatchQueue.main.async {
                self.spinner.isHidden = true
                if let error = error {
                    NSAlert.showSimpleAlert(window: self.window, isError: true, title: "Error", message: error.localizedDescription, completion: nil)
                }
                else {
                    self.reloadCurrentKeysAndValues(afterPushing: false)
                }
                
            }
        }
        
        currentStringsTableView.reloadData()
        
    }
    // MARK: - IBOutlets
    @IBOutlet weak var currentStringsTableView: NSTableView!
    @IBOutlet weak var newKeyTextField: NSTextField!
    @IBOutlet weak var newValueTextField: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var newStringsTableView: UIHelperTableView!
    @IBOutlet weak var ctaButton: NSButton!
    @IBOutlet weak var loadingLabel: NSTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var androidButton: NSButton!
    @IBOutlet weak var iosButton: NSButton!
    
    
    // MARK: - Private
    private var currentKeysAndValues: [KeyAndValue]?
    private var newKeysAndValuesToAdd = [KeyAndValue]()
    private var editedRowIndexes = Set<Int>()
    private let manager = BitbucketManager.shared
    private var selectedButton: NSButton?
    
    private var editedStrings: [String: KeyAndValue] {
        var dict = [String : KeyAndValue]()
        for row in editedRowIndexes {
            if let currentKey = currentKeyAndValueAtRow(row)?.key,
                let editedKeyAndValue = editedKeyAndValueAtRow(row) {
                dict[currentKey] = editedKeyAndValue
            }
        }
        return dict
    }
    
    
    // MARK: - Exposed Properties
    override var windowNibName: NSNib.Name? {
        return classNibName
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
        newStringsTableView.deleteDelegate = self
        currentKeysAndValues = manager.latestStrings?.displayTuples
        currentStringsTableView.reloadData()
        manager.delegate = self
        configureUI()
    }
}

// MARK: - Keys And Values
extension StringsListWindowController {
    
    private func addToKeysAndValues(key: String, value: String) {
        let keys = newKeysAndValuesToAdd.map() { $0.key }
        if keys.contains(key) {
            loadingLabel.isHidden = false
            loadingLabel.stringValue = "\(key) already in table!"
            return
        }
        let newTuple = (key: key, value: value)
        newKeysAndValuesToAdd.insert(newTuple, at: 0)
        resetTextFields()
        newStringsTableView.reloadData()
    }
    
    private func currentKeyAndValueAtRow(_ row: Int) -> KeyAndValue? {
        guard let currentKeysAndValues = currentKeysAndValues else {
            return nil
        }
        return currentKeysAndValues[row]
    }
    
    private func editedKeyAndValueAtRow(_ row: Int) -> KeyAndValue? {
        guard
            let keyCell = currentStringsTableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
            let valueCell = currentStringsTableView.view(atColumn: 1, row: row, makeIfNecessary: false) as? NSTableCellView,
            let newKey = keyCell.textField?.stringValue,
            let newValue = valueCell.textField?.stringValue else {
                return nil
        }
        return (newKey, newValue)
        
    }
    
    private func correctKeysAndValuesForTableVew(_ tableView: NSTableView) -> [KeyAndValue]? {
        if tableView == self.currentStringsTableView {
            return currentKeysAndValues
        }
        else {
            return newKeysAndValuesToAdd
        }
    }
}

// MARK: - UI
extension StringsListWindowController {
    
    private func configureUI() {
        if let title = manager.latestMessage {
            window?.title = "Commit: \(title)"
        }
        configureButtonStates()
        window?.center()
        let platform = UserDefaults.selectedPlatform
        selectedButton = (platform == .ios) ? iosButton : androidButton
        selectedButton?.state = .on
    }
    
    private func reset(error: StringEditError?) {
        // The spinner should always hide
        spinner.isHidden = true
        
        if let error = error {
            loadingLabel.isHidden = true
            NSAlert.showSimpleAlert(window: window, title: "Error", message: error.localizedDescription, completion: nil)
        }
        else {
            loadingLabel.stringValue = "Upload successful"
            newKeysAndValuesToAdd.removeAll()
            editedRowIndexes.removeAll()
            newStringsTableView.reloadData()
            reloadCurrentKeysAndValues(afterPushing: true)
        }
        resetTextFields()
    }
    
    private func reloadCurrentKeysAndValues(afterPushing: Bool) {
        currentKeysAndValues = manager.latestStrings?.displayTuples
        currentStringsTableView.reloadData()
        loadingLabel.isHidden = !afterPushing
    }
    
    private func resetTextFields() {
        newValueTextField.stringValue = ""
        newKeyTextField.stringValue = ""
        enableInterface(true)
        newKeyTextField.becomeFirstResponder()
    }
    
    private func enableInterface(_ enabled: Bool) {
        newKeyTextField.isEnabled = enabled
        newValueTextField.isEnabled = enabled
        configureButtonStates()
    }
    
    private func configureButtonStates() {
        addButton.isEnabled = !newKeyTextField.stringValue.isEmpty && !newValueTextField.stringValue.isEmpty
        ctaButton.isEnabled = !newKeysAndValuesToAdd.isEmpty || !editedStrings.isEmpty
    }
}

// MARK: - Table View Data Source
extension StringsListWindowController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.currentStringsTableView {
            return currentKeysAndValues?.count ?? 0
        }
        else if tableView == newStringsTableView {
            return newKeysAndValuesToAdd.count
        }
        return 0
    }
}

// MARK: - Table View Delegate
extension StringsListWindowController: NSTableViewDelegate, UIHelperTableViewDelegate {
    
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
            cell.textField?.target = self
            cell.textField?.action = #selector(edit(_:))
            return cell
        }
        return nil
    }
    
    func uiHelperTableViewShouldDeleteRow(tableView: UIHelperTableView, rowToDelete: Int) {
        newKeysAndValuesToAdd.remove(at: rowToDelete)
        newStringsTableView.reloadData()
        configureButtonStates()
    }
}

extension StringsListWindowController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        loadingLabel.isHidden = true
        configureButtonStates()
    }
    
    @objc private func edit(_ sender: NSTextField) {
        let rowToUpdate = currentStringsTableView.row(for: sender)
        
        guard rowToUpdate != 1, let currentKeyAndValue = currentKeyAndValueAtRow(rowToUpdate) else {
            return
        }
        
        let text = sender.stringValue.trimmingCharacters(in: .whitespaces)
        let shouldRefill = text.isEmpty
        
        if shouldRefill {
            if sender.isKeyTextField {
                sender.stringValue = currentKeyAndValue.key
            }
            else {
                sender.stringValue = currentKeyAndValue.value
            }
            return
        }
        
        editedRowIndexes.insert(rowToUpdate)
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
        case .fetching:
            loadingLabel.stringValue = "Fetching latest commit"
        case .pulling:
            loadingLabel.stringValue = "Pulling latest commit"
        case .pushing:
            loadingLabel.stringValue = "Pushing your changes"
        case .error(let error):
            loadingLabel.stringValue = "Error received: \(error.localizedDescription)"
        default:
            return
        }
    }
}
