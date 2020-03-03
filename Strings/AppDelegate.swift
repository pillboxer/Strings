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
    let controller = StringsListWindowController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #warning("Change Me")
        BitbucketManager.shared.load { (error) in
            DispatchQueue.main.async {
                self.controller.showWindow(nil)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

