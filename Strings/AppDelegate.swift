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
    let coordinator = Coordinator()

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        coordinator.start()
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

