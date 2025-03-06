//
//  MenuBarView.swift
//  Screenshot Editor
//
//  Created by Tokunaga Tetsuya on 2025/03/06.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20))
                Text("Screenshot Tool")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)
            
            Button(action: { screenshotManager.captureFullScreen() }) {
                Label("Capture Full Screen (⌘⇧1)", systemImage: "rectangle.dashed")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            Button(action: { screenshotManager.captureSelectedArea() }) {
                Label("Capture Selection (⌘⇧2)", systemImage: "crop")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            Divider()
            
            if let latestScreenshot = screenshotManager.currentScreenshot {
                VStack(alignment: .leading) {
                    Text("Latest Screenshot:")
                        .font(.subheadline)
                    
                    Image(nsImage: latestScreenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .cornerRadius(6)
                        .onTapGesture {
                            screenshotManager.isEditing = true
                            if let popover = NSApplication.shared.delegate as? AppDelegate {
                                popover.popover?.performClose(nil)
                            }
                        }
                }
            }
            
            Spacer()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
        .padding()
        .frame(width: 280)
    }
}
