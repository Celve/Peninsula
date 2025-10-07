//
//  Dock.swift
//  Peninsula
//
//  Created by Linyu Wu on 12/22/24.
//

import AppKit

class Dock {
    static var shared = Dock()
    var axList: AXUIElement?
    var apps: [String] = []
    
    init() {
        fetchAx()
        refresh()
    }
    
    func fetchAx() {
        guard let dockProcessId = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.dock"
            ).last?.processIdentifier
        else { return }

        let dock = AXUIElementCreateApplication(dockProcessId)
        self.axList = try? dock.children()?.first { try $0.role() == kAXListRole }
        if self.axList == nil {
            PeninsulaLog.accessibility.error("Failed to fetch dock accessibility list")
        }
    }
    
    func refresh() {
        if self.axList == nil {
            fetchAx()
        }
        if let axList = self.axList {
            if let children = (try? axList.children()?.filter { try $0.subrole() == kAXApplicationDockItemSubrole}) {
                apps.removeAll()
                for child in children {
                    if let title = try? child.title() {
                        apps.append(title)
                    }
                }
            }
        }
    }
}
