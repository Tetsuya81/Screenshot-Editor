//
//  AppDelegate.swift
//  Screenshot Editor
//
//  Created by Tokunaga Tetsuya on 2025/03/06.
//

import SwiftUI
import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        registerGlobalHotkeys()
    }
    
    private func setupMenuBar() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView().environmentObject(ScreenshotManager.shared))
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Screenshot Tool")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    @objc private func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover?.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    private func registerGlobalHotkeys() {
        // Command + Shift + 1 for full screen
        registerHotKey(keyCode: kVK_ANSI_1, modifier: [.command, .shift]) { [weak self] in
            self?.captureFullScreen()
        }
        
        // Command + Shift + 2 for selected area
        registerHotKey(keyCode: kVK_ANSI_2, modifier: [.command, .shift]) { [weak self] in
            self?.captureSelectedArea()
        }
    }
    
    private func registerHotKey(keyCode: Int, modifier: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        var eventSpecTrigger = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // Create a unique ID for this hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B534854), id: UInt32(keyCode))
        
        // Setup hotkey reference
        var hotKeyRef: EventHotKeyRef?
        let modifierKeys = UInt32(modifier.rawValue >> 16)
        
        // Register the hotkey
        RegisterEventHotKey(UInt32(keyCode), modifierKeys, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        // Create a handler for when the hotkey is pressed
        let handlerRef = UnsafeMutableRawPointer(Unmanaged.passRetained(EventHandler(action: action)).toOpaque())
        
        // Install the handler
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            let handler = Unmanaged<EventHandler>.fromOpaque(userData!).takeUnretainedValue()
            handler.action()
            return noErr
        }, 1, &eventSpecTrigger, handlerRef, nil)
    }
    
    private func captureFullScreen() {
        ScreenshotManager.shared.captureFullScreen()
    }
    
    private func captureSelectedArea() {
        ScreenshotManager.shared.captureSelectedArea()
    }
}

// Event handler class for hotkeys
class EventHandler {
    let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
}
