//
//  Dock.swift
//  Peninsula
//
//  Created by Linyu Wu on 12/22/24.
//

import AppKit

class Dock {
    static var shared = Dock()
    var axList: AxElement!
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

        let dock = AxElement(element: AXUIElementCreateApplication(dockProcessId))
        self.axList = try? dock.children()?.first { try $0.role() == kAXListRole }
    }
    
    func refresh() {
        if let children = (try? self.axList.children()?.filter { try $0.subrole() == kAXApplicationDockItemSubrole}) {
            apps.removeAll()
            for child in children {
                if let title = try? child.title() {
                    apps.append(title)
                }
            }
        }
    }
}
