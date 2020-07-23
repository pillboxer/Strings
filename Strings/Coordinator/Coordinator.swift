//
//  Coordinator.swift
//  Strings
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import StringEditorFramework

protocol CoordinatorDelegate: class {
    func coordinatorDidLogout(_ coordinator: Coordinator)
    func coordinatorDidLogin(_ coordinator: Coordinator)
}

class Coordinator {
    
    // MARK: - Private Properties
    private var currentController: NSWindowController = LaunchScreenWindowController()
    private enum ControllerType {
        case login
        case strings
    }
    private var controllerType: ControllerType?
    weak var delegate: CoordinatorDelegate?
    
    // MARK: - Exposed Methods
    func start() {
        currentController.showWindow(nil)
        loadFromBitbucket()
    }
    
    func logout() {
        BitbucketManager.shared.logout()
        controllerType = .login
        loadController()
    }
    
    // MARK: - Private Methods
    private func loadFromBitbucket() {
        BitbucketManager.shared.load { (error) in
            if let error = error {
                self.controllerType = .login
                if !error.isNoCredentialsError {
                    self.showErrorAndReturnToLogin(error)
                    return
                }
            }
            else {
                self.controllerType = .strings
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
                self.loadController()
            }
        }
    }
    
    private func showErrorAndQuit(_ error: RequestError) {
        DispatchQueue.main.async {
            NSAlert.showSimpleAlert(window: self.currentController.window, isError: true, title: "Something Went Wrong", message: error.localizedDescription) {
                NSApp.terminate(nil)
            }
        }
    }
    
    private func showErrorAndReturnToLogin(_ error: RequestError) {
        DispatchQueue.main.async {
            NSAlert.showSimpleAlert(window: self.currentController.window, isError: true, title: "Something Went Wrong", message: error.localizedDescription) {
                self.loadController()
            }
        }
    }
    
    private func loadController() {
        currentController.close()
        guard let controllerType = controllerType else {
            return
        }
        switch controllerType {
        case .login:
            let controller = LoginWindowController()
            controller.delegate = self
            currentController = controller
            self.delegate?.coordinatorDidLogout(self)
        case .strings:
            currentController = StringsListWindowController()
            self.delegate?.coordinatorDidLogin(self)
        }
        currentController.showWindow(nil)
        currentController.window?.center()
    }
    
}

extension Coordinator: LoginWindowControllerDelegate {
    
    func loginWindowControllerDidStoreCredentials(_ controller: LoginWindowController) {
        currentController.close()
        currentController = LaunchScreenWindowController()
        start()
    }
}
