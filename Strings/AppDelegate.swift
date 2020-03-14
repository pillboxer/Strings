//
//  AppDelegate.swift
//  Strings
//
//  Created by Henry Cooper on 03/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa
import StringEditorFramework

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var loginLogoutButton: NSMenuItem!
    let coordinator = Coordinator()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        coordinator.delegate = self
        window.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        loginLogoutButton.isHidden = true
        coordinator.start()
    }
        
    @IBAction func logout(_ sender: Any) {
        coordinator.logout()
    }
    
}

extension AppDelegate: CoordinatorDelegate {
    
    func coordinatorDidLogin(_ coordinator: Coordinator) {
        loginLogoutButton.isHidden = false
        loginLogoutButton.isEnabled = true
        loginLogoutButton.title = "Logout"
    }
    
    func coordinatorDidLogout(_ coordinator: Coordinator) {
        loginLogoutButton.isHidden = false
        loginLogoutButton.title = "Login"
        loginLogoutButton.isEnabled = false
    }
}

