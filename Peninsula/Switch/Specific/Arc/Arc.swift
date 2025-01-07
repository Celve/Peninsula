//
//  Arc.swift
//  Peninsula
//
//  Created by Linyu Wu on 12/24/24.
//
import Foundation
import Cocoa
import AppKit
import ApplicationServices.HIServices
import ScriptingBridge


//class ArcApplication: Application {
//    var arcScriptingApp: ArcScriptingApplication
//    var arcScriptingWindows: [ArcScriptingWindow]
//    
//    override init(runningApplication: NSRunningApplication, globalOrder: Int) {
//        self.arcScriptingApp = SBApplication(bundleIdentifier: runningApplication.bundleIdentifier!)!
//        self.arcScriptingApp.activate()
//        self.arcScriptingWindows = arcScriptingApp.windows?() as! [any ArcScriptingWindow]
//        super.init(runningApplication: runningApplication, globalOrder: globalOrder)
//        for window in arcScriptingWindows {
//            let tabs = window.tabs?() as! [any ArcScriptingTab]
//            if tabs.count > 0 {
//                tabs[0].select?()
//            }
//        }
//    }
//}

//class ArcWindow: Window {
//    
//}

class ArcTab {
    var arcScriptingTab: ArcScriptingTab
    
    init(arcScriptingTab: ArcScriptingTab) {
        self.arcScriptingTab = arcScriptingTab
    }
    
    func focus() {
        arcScriptingTab.select?()
    }
}
