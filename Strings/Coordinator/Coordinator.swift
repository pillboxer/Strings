//
//  Coordinator.swift
//  Strings
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import StringEditorFramework

protocol Coordinatable {
    var coordinator: Coordinator { get set }
}

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
        
        self.currentController.showWindow(nil)
        BitbucketManager.shared.load { (error) in
            if let error = error {
                switch error {
                case .noCredentials, .badCredentials:
                    self.controllerType = .login
                default:
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
    
    // MARK: - Private Methods
    private func loadController() {
        currentController.close()
        guard let controllerType = controllerType else {
            return
        }
        switch controllerType {
        case .login:
            currentController = LoginWindowController()
        case .strings:
            currentController = StringsListWindowController()
        }
        currentController.showWindow(nil)
        currentController.window?.center()
    }
    
}
