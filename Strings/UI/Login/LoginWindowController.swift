//
//  LoginWindowController.swift
//  Strings
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import StringEditorFramework
import UIHelper

protocol LoginWindowControllerDelegate: class {
    func loginWindowControllerDidStoreCredentials(_ controller: LoginWindowController)
}

class LoginWindowController: NSWindowController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    // MARK: - Action Methods
    @IBAction func ctaPressed(_ sender: Any) {
        disableInterfaceForLogin(true)
        guard BitbucketManager.shared.storeCredentials(username: username, password: password) else {
            #warning("Handle")
            return
        }
        self.delegate?.loginWindowControllerDidStoreCredentials(self)
    }
    
    // MARK: - Exposed Properties
    override var windowNibName: NSNib.Name? {
        return classNibName
    }
    
    weak var delegate: LoginWindowControllerDelegate?
    
    // MARK: - Private Properties
    var username: String {
        return usernameTextField.stringValue
    }
    
    var password: String {
        return passwordTextField.stringValue
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
    }
    
    // MARK: - Private Methods
    private func configureButtonStates() {
        loginButton.isEnabled = !(usernameTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty)
    }
    
    private func disableInterfaceForLogin(_ disabled: Bool) {
        loginButton.isHidden = disabled
        spinner.isHidden = !disabled
        disabled ? spinner.startAnimation(nil) : spinner.stopAnimation(nil)
    }
    
    private func showErrorAlert(_ error: LoginError) {
        NSAlert.showSimpleAlert(window: window, isError: true, title: "Login Failed", message: "Error received: \(error.localizedDescription)") {
            self.clearTextFields()
        }
    }
    
    private func clearTextFields() {
        usernameTextField.stringValue = ""
        passwordTextField.stringValue = ""
        usernameTextField.becomeFirstResponder()
        disableInterfaceForLogin(false)
    }
}

extension LoginWindowController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        configureButtonStates()
    }
    
}
