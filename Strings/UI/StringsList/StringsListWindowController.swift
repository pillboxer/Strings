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
        let newValue = newValueTextField.string.trimmingCharacters(in: .whitespaces)
        addToKeysAndValues(key: newKey, value: newValue)
    }
    
    @IBAction func ctaButtonPressed(_ sender: Any) {
        enableInterface(false)
        // Manually disable so we can't spam
        ctaButton.isEnabled = false
        manager.addToStrings(keysAndValues: newKeysAndValuesToAdd, editedStrings: editedStrings, commitMessage: commitMessage) { [weak self] (error) in
            DispatchQueue.main.async {
                self?.reset(error: error)
            }
        }
    }
    
    @IBAction func environmentButtonPressed(_ sender: Any) {
        
        shouldContinueAfterCheckingForUncommittedChanges { (shouldContinue) in
            if shouldContinue {
                Environment.setEnvironment(!Environment.isDev)
                BitbucketManager.shared.load { (error) in
                    DispatchQueue.main.async {
                        self.spinner.isHidden = true
                        if let error = error {
                            self.showErrorAlert(error)
                        }
                        else {
                            self.reloadCurrentKeysAndValues(afterPushing: false)
                            self.setTitle(string: self.manager.latestMessage)
                        }
                    }
                }
            }
            else {
                return
            }
        }
    }
    
    @IBAction func filterButtonPressed(_ sender: NSButton) {
        
        if sender.state == .off {
            cancelFilter()
            return
        }
        filterEnabled = true
        
        NSAlert.showSingleTextFieldAlert(window: window, title: "Filter", textFieldPlaceholder: "Key Or Value", returnButtonTitle: "Filter") { (filterValue) in
            if let filterValue = filterValue {
                self.topTableView.scrollRowToVisible(0)
                self.filterKeysAndValues(text: filterValue)
            }
            else {
                self.cancelFilter()
            }
        }
    }
    
    @IBAction func radioButtonSelected(_ sender: NSButton) {
        guard sender != selectedButton else {
            return
        }
        let newPlatform: Platform = (sender == iosButton) ? .ios : .android
        let oldPlatformButton = (sender == iosButton) ? androidButton : iosButton
        
        shouldContinueAfterCheckingForUncommittedChanges { (shouldContinue) in
            if shouldContinue {
                self.editedKeysAndValues.removeAll()
                BitbucketManager.shared.changePlatformTo(newPlatform) { (error) in
                    DispatchQueue.main.async {
                        self.cancelFilter()
                        self.spinner.isHidden = true
                        if let error = error {
                            self.showErrorAlert(error)
                            oldPlatformButton?.state = .on
                        }
                        else {
                            self.selectedButton = sender
                            self.configurePopUpButtonConstraintsForPlatform(newPlatform)
                            self.reloadCurrentKeysAndValues(afterPushing: false)
                            self.setTitle(string: self.manager.latestMessage)
                        }
                    }
                }
            }
            else {
                oldPlatformButton?.state = .on
            }
        }
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var topTableView: NSTableView!
    @IBOutlet weak var newKeyTextField: NSTextField!
    @IBOutlet weak var newValueTextField: PlaceholderTextView!
    @IBOutlet weak var commitMessageTextField: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var bottomTableView: UIHelperTableView!
    @IBOutlet weak var ctaButton: NSButton!
    @IBOutlet weak var loadingLabel: NSTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var androidButton: NSButton!
    @IBOutlet weak var iosButton: NSButton!
    @IBOutlet weak var newValueTextFieldToLanguageConstraint: NSLayoutConstraint!
    @IBOutlet weak var newValueTextFieldToSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet  var newKeyTextFieldToBottomTableViewConstraint: NSLayoutConstraint!
    @IBOutlet  var addButtonToBottomTableViewConstraint: NSLayoutConstraint!
    @IBOutlet  var newValueTextFieldToBottomTableViewConstraint: NSLayoutConstraint!
    @IBOutlet  var languagePopUpToBottomTableViewConstraint: NSLayoutConstraint!
    @IBOutlet  var newValueTextFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet  var bottomTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var languagePopUp: NSPopUpButton!
    @IBOutlet weak var environmentButton: NSButton!
    @IBOutlet weak var filterButton: NSButton!
    
    // MARK: - Private
    private let manager = BitbucketManager.shared
    
    private var originalKeysAndValues: [KeyAndValue]?
    private var currentKeysAndValues: [KeyAndValue]?
    private var filteredKeysAndValues: [KeyAndValue]?
    private var editedKeysAndValues = [Int: KeyAndValue]() {
        didSet {
            updateCurrentKeysAndValues()
        }
    }
    private var filterEnabled = false
    private var newKeysAndValuesToAdd = [KeyAndValue]()
    private var selectedButton: NSButton?
    private var editedStrings: [String: KeyAndValue] {
        var dict = [String : KeyAndValue]()
        for (row, keyAndValue) in editedKeysAndValues {
            if let currentKey = currentKeyAndValueAtRow(row)?.key {
                dict[currentKey] = keyAndValue
            }
        }
        return dict
    }
    private var selectedLanguage: KeyAndValue.Language {
        if let title = languagePopUp.selectedItem?.title,
            let language = KeyAndValue.Language(title: title) {
            return language
        }
        return .en
    }
    
    private var constraintsToAnimate: [NSLayoutConstraint] {
       return [languagePopUpToBottomTableViewConstraint, addButtonToBottomTableViewConstraint, newKeyTextFieldToBottomTableViewConstraint, newValueTextFieldToBottomTableViewConstraint]
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
        newValueTextField.placeholderDelegate = self
        bottomTableView.deleteDelegate = self
        originalKeysAndValues = manager.displayTuples
        currentKeysAndValues = originalKeysAndValues
        topTableView.reloadData()
        manager.delegate = self
        configureUI()
    }
}

// MARK: - Keys And Values
extension StringsListWindowController {
    
    private func addToKeysAndValues(key: String, value: String) {
        let keys = newKeysAndValuesToAdd.map() { $0.key }
        let newKeyAndValue = KeyAndValue(key: key, value: value, language: selectedLanguage)
        let alreadyInTopTable = (currentKeysAndValues?.contains() { $0.key == key }) ?? false
        if keys.contains(key) || alreadyInTopTable {
            let message = alreadyInTopTable ? "\(key) already in strings above!" : "\(key) already added below!"
            loadingLabel.isHidden = false
            loadingLabel.stringValue = message
            return
        }
        newKeysAndValuesToAdd.insert(newKeyAndValue, at: 0)
        resetTextFields()
        bottomTableView.reloadData()
    }
    
    private func topTableViewKeyAndValueAtRow(_ row: Int) -> KeyAndValue? {
        if let _ = filteredKeysAndValues {
            return filteredKeyAndValueAtRow(row)
        }
        else if let _ = currentKeysAndValues {
            return currentKeyAndValueAtRow(row)
        }
        return nil
    }
    
    private func currentKeyAndValueAtRow(_ row: Int) -> KeyAndValue? {
        return currentKeysAndValues?[row]
    }
    
    private func filteredKeyAndValueAtRow(_ row: Int) -> KeyAndValue? {
        return filteredKeysAndValues?[row]
    }
    
    
    private func correctKeysAndValuesForTableVew(_ tableView: NSTableView) -> [KeyAndValue]? {
        if tableView == self.topTableView {
            return correctKeysAndValuesForTopTableView?.sorted() { $0.key < $1.key }
        }
        else {
            return newKeysAndValuesToAdd.sorted() { $0.key < $1.key }
        }
    }
    
    private var correctKeysAndValuesForTopTableView: [KeyAndValue]? {
        return  filteredKeysAndValues ?? currentKeysAndValues
    }
    
    private var commitMessage: String {
        return commitMessageTextField.stringValue
    }
    
    private func filterKeysAndValues(text: String) {
        filteredKeysAndValues = currentKeysAndValues?.compactMap() { keyAndValue in
            if keyAndValue.key.localizedCaseInsensitiveContains(text) || keyAndValue.value.localizedCaseInsensitiveContains(text) {
                return keyAndValue
            }
            else {
                return nil
            }
        }
        topTableView.reloadData()
    }
    
    private func updateCurrentKeysAndValues() {
        for (row, keyAndValue) in editedKeysAndValues {
            let newKeyAndValue = KeyAndValue(key: keyAndValue.key, value: keyAndValue.value, language: keyAndValue.language)
            currentKeysAndValues?[row] = newKeyAndValue
        }
    }
    
}

// MARK: - UI
extension StringsListWindowController {
    
    private func configureUI() {
        setTitle(string: manager.latestMessage)
        resetTextFields()
        configureButtonStates()
        window?.center()
        let platform = UserDefaults.selectedPlatform
        configurePopUpButtonConstraintsForPlatform(platform)
        selectedButton = (platform == .ios) ? iosButton : androidButton
        selectedButton?.state = .on
        configurePopUp()
        configureEnvironmentButton()
    }
    
    private func configurePopUpButtonConstraintsForPlatform(_ platform: Platform) {
        let isIos = platform == .ios
        newValueTextFieldToLanguageConstraint.priority = isIos ? .defaultLow : .defaultHigh
        newValueTextFieldToSuperviewConstraint.priority = isIos ? .defaultHigh : .defaultLow
        languagePopUp.isHidden = platform == .ios
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
            editedKeysAndValues.removeAll()
            bottomTableView.reloadData()
            let string = commitMessage.isEmpty ? "Edited With Bitbucket" : commitMessage
            setTitle(string: string)
            reloadCurrentKeysAndValues(afterPushing: true)
        }
        resetTextFields()
    }
    
    private func setTitle(string: String?) {
        if let string = string {
            window?.title = "Commit: \(string)"
        }
    }
    
    private func cancelFilter() {
        filteredKeysAndValues = nil
        topTableView.reloadData()
        topTableView.scrollRowToVisible(0)
        filterButton.state = .off
    }
    
    private func configurePopUp() {
        for language in KeyAndValue.Language.allCases {
            languagePopUp.addItem(withTitle: language.rawValue.uppercased())
        }
    }
    
    private func reloadCurrentKeysAndValues(afterPushing: Bool) {
        originalKeysAndValues = manager.displayTuples
        currentKeysAndValues = originalKeysAndValues
        cancelFilter()
        loadingLabel.isHidden = !afterPushing
        configureButtonStates()
        commitMessageTextField.stringValue = ""
        configureEnvironmentButton()
    }
    
    private func resetTextFields() {
        newValueTextField.string = ""
        newKeyTextField.stringValue = ""
        newValueTextField.placeholderAttributedString = NSMutableAttributedString(string: "New Value")
        enableInterface(true)
        newKeyTextField.becomeFirstResponder()
    }
    
    private func enableInterface(_ enabled: Bool) {
        newKeyTextField.isEnabled = enabled
        newValueTextField.isEditable = enabled
        configureButtonStates()
    }
    
    private func configureButtonStates() {
        addButton.isEnabled = !newKeyTextField.stringValue.isEmpty && !newValueTextField.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ctaButton.isEnabled = !newKeysAndValuesToAdd.isEmpty || !editedStrings.isEmpty
    }
    
    private func showErrorAlert(_ error: RequestError) {
        NSAlert.showSimpleAlert(window: self.window, isError: true, title: "Error", message: error.localizedDescription) {
            self.loadingLabel.isHidden = true
        }
    }
    
    private func configureEnvironmentButton() {
        if Environment.isDev {
            environmentButton.image = NSImage(named: NSImage.Name("NSStatusPartiallyAvailable"))
        }
        else {
            environmentButton.image = NSImage(named: NSImage.Name("NSStatusUnavailable"))
        }
    }
    
    private func shouldContinueAfterCheckingForUncommittedChanges(completion: @escaping (Bool) -> Void) {
        guard !editedKeysAndValues.isEmpty else {
            completion(true)
            return
        }
        
        let changeOrChanges = (editedKeysAndValues.count == 1) ? "change" : "changes"
        NSAlert.showDualButtonAlert(window: window, title: "Unsaved Changes", message: "You currently have \(editedKeysAndValues.count) unsaved \(changeOrChanges). Are you sure you wish to continue?", returnButtonTitle: "Discard My Changes And Continue") { response in
            completion(response == .alertFirstButtonReturn)
        }
    }
}

// MARK: - Table View Data Source
extension StringsListWindowController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.topTableView {
            return numberOfRowsForCurrentOrFilteredTableView
        }
        else if tableView == bottomTableView {
            return numberOfRowsForNewKeysAndValuesTableView
        }
        return 0
    }
    
    private var numberOfRowsForCurrentOrFilteredTableView: Int {
        if let _ = filteredKeysAndValues {
            return filteredKeysAndValues?.count ?? 0
        }
        else {
            return currentKeysAndValues?.count ?? 0
        }
    }
    
    private var numberOfRowsForNewKeysAndValuesTableView: Int {
        return newKeysAndValuesToAdd.count
    }
}

// MARK: - Table View Delegate
extension StringsListWindowController: NSTableViewDelegate, UIHelperTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn, let keysAndValues = correctKeysAndValuesForTableVew(tableView) else {
            return nil
        }
        
        let keyAndValue = keysAndValues[row]
        let key = keyAndValue.key
        let value = keyAndValue.value
        
        let identifier: String
        let text: String
        
        switch column.identifier {
        case .key:
            identifier = "KeyView"
            text = key
        case .value:
            identifier = "ValueView"
            text = value
        default:
            identifier = ""
            text = ""
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(identifier), owner: nil) as? NSTableCellView {
            
            let rowView = tableView.rowView(atRow: row, makeIfNecessary: false)
            
            if tableView == topTableView {
                cell.textField?.textColor = keyAndValue.isSeparator ? .white : .labelColor
                let currentBackgroundColor = rowView?.backgroundColor ?? .clear
                rowView?.backgroundColor = keyAndValue.isSeparator ? .black : currentBackgroundColor
            }
            
            cell.textField?.stringValue = text
            cell.textField?.target = self
            cell.textField?.action = #selector(edit(_:))
            cell.textField?.delegate = self
            return cell
        }
        return nil
    }
    
    func uiHelperTableViewShouldDeleteRow(tableView: UIHelperTableView, rowToDelete: Int) {
        newKeysAndValuesToAdd.remove(at: rowToDelete)
        bottomTableView.reloadData()
        configureButtonStates()
    }
}

extension StringsListWindowController: NSTextFieldDelegate, NSTextViewDelegate, PlaceholderTextViewDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        loadingLabel.isHidden = true
        configureButtonStates()
    }
    
    func textDidChange(_ notification: Notification) {
        loadingLabel.isHidden = true
        configureButtonStates()
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let object = obj.object as? NSTextField, object == newKeyTextField, newKeyTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newKeyTextField.stringValue = ""
        }
    }
    
    func placeholderTextViewFocusChanged(_ placeholderTextView: PlaceholderTextView, inFocus: Bool) {
        NSAnimationContext.runAnimationGroup() { _ in
            NSAnimationContext.current.duration = 0.4
            NSAnimationContext.current.allowsImplicitAnimation = true
            bottomTableHeightConstraint.constant -= inFocus ? 100 : -100
            self.window?.layoutIfNeeded()
        }
        
        for constraint in constraintsToAnimate {
            constraint.isActive = !inFocus
        }
        newValueTextFieldHeightConstraint.constant += inFocus ? 100.0 : -100.0
        
    }

    @objc private func edit(_ sender: NSTextField) {
        let text = sender.stringValue.trimmingCharacters(in: .whitespaces)
        // 'Updating' means to change the text of a specific row. There are potentially two rows to update, depending on whether we are filtering or not.
        let visibleRow = topTableView.row(for: sender)
        guard visibleRow != -1,
            let currentKeyAndValueToUpdate = topTableViewKeyAndValueAtRow(visibleRow),
            let rowToIndex = currentKeysAndValues?.firstIndex(of: currentKeyAndValueToUpdate),
            let existingKeyAndValue = currentKeysAndValues?[rowToIndex],
            let originalKeyAndValue = originalKeysAndValues?[rowToIndex] else {
                return
        }
        
        // Is the string the same?
        let newKey = sender.isKeyTextField ? text : existingKeyAndValue.key
        let newValue = sender.isKeyTextField ? existingKeyAndValue.value : text
        let newKeyAndValue = KeyAndValue(key: newKey, value: newValue, language: existingKeyAndValue.language)
        
        let newKeyAlreadyExists = currentKeysAndValues?.contains() { newKey == $0.key  } ?? false
        if sender.isKeyTextField && newKeyAlreadyExists {
            NSAlert.showSimpleAlert(window: window, isError: true, title: "Error", message: "\(newKey) already exists in the JSON. You'll need to edit that string") {
                sender.stringValue = existingKeyAndValue.key
            }
            return
        }
        
        if newKeyAndValue == originalKeyAndValue {
            editedKeysAndValues.removeValue(forKey: rowToIndex)
            currentKeysAndValues?[rowToIndex] = originalKeyAndValue
            filteredKeysAndValues?[visibleRow] = originalKeyAndValue
            configureButtonStates()
            return
        }
        
        let editingContentVersion = (sender.isKeyTextField && existingKeyAndValue.key.isContentVersion)
        // Has the string been left empty?
        let shouldRefill = text.isEmpty || editingContentVersion
        if shouldRefill {
            sender.stringValue = existingKeyAndValue.key
            return
        }
        
        editedKeysAndValues[rowToIndex] = newKeyAndValue
        filteredKeysAndValues?[visibleRow] = newKeyAndValue
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

private extension String {
    var isContentVersion: Bool {
        return self == "content_version"
    }
}

private extension NSUserInterfaceItemIdentifier {
    
    static var key: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier("KeyColumn")
    }
    
    static var value: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier("ValueColumn")
    }
}

