//
//  Coordinator.swift
//  Strings
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import StringEditorFramework

class Coordinator {
    
    // MARK: - Private Properties
    private var currentController: NSWindowController = LaunchScreenWindowController()
    private enum ControllerType {
        case login
        case strings
    }
    private var controllerType: ControllerType?
    
    // MARK: - Exposed Methods
    func start() {
        currentController.showWindow(nil)
        loadFromBitbucket()
    }
    
    // MARK: - Private Methods
    private func loadFromBitbucket() {
        BitbucketManager.shared.load { (error) in
            if let error = error {
                switch error {
                case .noCredentials, .badCredentials:
                    self.controllerType = .login
                default:
                    self.showErrorAndQuit(error)
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
        case .strings:
            currentController = StringsListWindowController()
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
