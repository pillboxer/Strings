//
//  LaunchScreenWindowController.swift
//  Strings
//
//  Created by Henry Cooper on 06/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import StringEditorFramework
import UIHelper
import Cocoa

class LaunchScreenWindowController: NSWindowController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var loadingStatusLabel: NSTextField!
    
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
        BitbucketManager.shared.delegate = self
        configureUI()
    }
    
    private func configureUI() {
        window?.center()
    }
    
}

extension LaunchScreenWindowController: BitbucketManagerDelegate {
    
    func bitbucketManagerLoadingStateDidChange(_ newState: LoadingState) {
        
        DispatchQueue.main.async {
            switch newState {
            case .fetching:
                self.progressBar.isHidden = false
                self.progressBar.animate(toDoubleValue: 25)
                self.loadingStatusLabel.stringValue = "Checking credentials"
            case .pulling:
                self.progressBar.animate(toDoubleValue: 50)
                self.loadingStatusLabel.stringValue = "Pulling Latest Changes..."
            case .complete:
                self.loadingStatusLabel.stringValue = "Finishing..."
                self.progressBar.animate(toDoubleValue: 100)
            case .error(let error):
                self.handleLoadError(error)
            default:
                return
            }
        }
    }
    
    private func handleLoadError(_ error: LoadError) {
        switch error {
        case .requestError(let error):
            self.progressBar.isHidden = true
            self.loadingStatusLabel.stringValue = "Request Error: \(error.localizedDescription)"
        default:
            return
        }
    }
    
}
