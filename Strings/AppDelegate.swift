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
        guard  #available(OSX 10.15, *) else {
            NSAlert.showSimpleAlert(window: window, isError: true, title: "Error", message: "You need to be running MacOS 10.15 or later. Please update your system", completion: nil)
            NSApp.terminate(nil)
            return
        }
        coordinator.delegate = self
        window.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        loginLogoutButton.isHidden = true
        coordinator.start()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        coordinator.start()
        return true
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

