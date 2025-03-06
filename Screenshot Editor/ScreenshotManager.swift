//
//  ScreenshotManager.swift
//  Screenshot Editor
//
//  Created by Tokunaga Tetsuya on 2025/03/06.
//

import SwiftUI
import Cocoa
import AppKit

class ScreenshotManager: ObservableObject {
    static let shared = ScreenshotManager()
    
    @Published var currentScreenshot: NSImage?
    @Published var isEditing = false
    @Published var annotations: [Annotation] = []
    @Published var selectedTool: AnnotationTool = .highlight
    @Published var selectedColor: Color = .yellow
    @Published var textInput: String = ""
    @Published var fontsize: CGFloat = 16
    
    private init() {}
    
    func captureFullScreen() {
        hideUI {
            if let screen = NSScreen.main {
                let rect = screen.frame
                self.captureScreenshot(of: rect)
            }
        }
    }
    
    func captureSelectedArea() {
        hideUI {
            // Use CGDisplayCreateImage for selected area
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-i", "-o", "-c"] // interactive, no shadow, to clipboard
            
            try? task.run()
            task.waitUntilExit()
            
            // Get image from clipboard
            if let pasteboard = NSPasteboard.general.pasteboardItems?.first,
               let data = pasteboard.data(forType: .tiff),
               let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.currentScreenshot = image
                    self.isEditing = true
                    self.annotations = []
                }
            }
        }
    }
    
    private func captureScreenshot(of rect: CGRect) {
        // Use screencapture command line tool instead of deprecated CGWindowListCreateImage
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_screenshot.png")
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-x", temporaryURL.path] // -x for no sound
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if let imageData = try? Data(contentsOf: temporaryURL),
               let screenshot = NSImage(data: imageData) {
                DispatchQueue.main.async {
                    self.currentScreenshot = screenshot
                    self.isEditing = true
                    self.annotations = []
                }
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: temporaryURL)
            }
        } catch {
            print("Failed to capture screenshot: \(error)")
        }
    }
    
    private func hideUI(completion: @escaping () -> Void) {
        // Give time for UI to hide
        DispatchQueue.main.async {
            NSApp.hide(nil)
            // Small delay to ensure app is hidden
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion()
                // Show app again after screenshot
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.unhide(nil)
                }
            }
        }
    }
    
    func addTextAnnotation(at position: CGPoint) {
        guard !textInput.isEmpty else { return }
        
        let annotation = Annotation(
            type: .text,
            startPoint: position,
            endPoint: position,
            color: selectedColor,
            text: textInput,
            fontSize: fontsize
        )
        
        annotations.append(annotation)
        textInput = ""
    }
    
    func addHighlightAnnotation(from startPoint: CGPoint, to endPoint: CGPoint) {
        let annotation = Annotation(
            type: .highlight,
            startPoint: startPoint,
            endPoint: endPoint,
            color: selectedColor,
            text: "",
            fontSize: fontsize
        )
        
        annotations.append(annotation)
    }
    
    func addArrowAnnotation(from startPoint: CGPoint, to endPoint: CGPoint) {
        let annotation = Annotation(
            type: .arrow,
            startPoint: startPoint,
            endPoint: endPoint,
            color: selectedColor,
            text: "",
            fontSize: fontsize
        )
        
        annotations.append(annotation)
    }
    
    func saveScreenshot() {
        guard let screenshot = currentScreenshot else { return }
        
        // Create a save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "Screenshot \(Date().formatted(.dateTime.year().month().day().hour().minute().second()))"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.renderAndSaveImage(to: url)
            }
        }
    }
    
    private func renderAndSaveImage(to url: URL) {
        guard let screenshot = currentScreenshot else { return }
        
        let imageSize = screenshot.size
        let imageRect = CGRect(origin: .zero, size: imageSize)
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(imageSize.width),
            pixelsHigh: Int(imageSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return }
        
        bitmapRep.size = imageSize
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        
        // Draw the screenshot
        screenshot.draw(in: imageRect)
        
        // Draw all annotations
        for annotation in annotations {
            switch annotation.type {
            case .highlight:
                drawHighlight(annotation, in: NSGraphicsContext.current!)
            case .text:
                drawText(annotation, in: NSGraphicsContext.current!)
            case .arrow:
                drawArrow(annotation, in: NSGraphicsContext.current!)
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
        
        if let imageData = bitmapRep.representation(using: .png, properties: [:]) {
            try? imageData.write(to: url)
        }
    }
    
    private func drawHighlight(_ annotation: Annotation, in context: NSGraphicsContext) {
        let rect = CGRect(
            x: min(annotation.startPoint.x, annotation.endPoint.x),
            y: min(annotation.startPoint.y, annotation.endPoint.y),
            width: abs(annotation.endPoint.x - annotation.startPoint.x),
            height: abs(annotation.endPoint.y - annotation.startPoint.y)
        )
        
        let nsColor = NSColor(annotation.color)
        nsColor.withAlphaComponent(0.4).setFill()
        
        let path = NSBezierPath(rect: rect)
        path.fill()
        
        nsColor.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    private func drawText(_ annotation: Annotation, in context: NSGraphicsContext) {
        let nsColor = NSColor(annotation.color)
        let font = NSFont.systemFont(ofSize: annotation.fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nsColor
        ]
        
        annotation.text.draw(at: annotation.startPoint, withAttributes: attributes)
    }
    
    private func drawArrow(_ annotation: Annotation, in context: NSGraphicsContext) {
        let nsColor = NSColor(annotation.color)
        nsColor.setStroke()
        
        let startPoint = annotation.startPoint
        let endPoint = annotation.endPoint
        
        // Draw the line
        let linePath = NSBezierPath()
        linePath.move(to: startPoint)
        linePath.line(to: endPoint)
        linePath.lineWidth = 2
        linePath.stroke()
        
        // Calculate arrow head
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = CGFloat.pi / 8
        
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let angle = atan2(dy, dx)
        
        let arrowPoint1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        
        // Draw arrow head
        let arrowPath = NSBezierPath()
        arrowPath.move(to: endPoint)
        arrowPath.line(to: arrowPoint1)
        arrowPath.move(to: endPoint)
        arrowPath.line(to: arrowPoint2)
        arrowPath.lineWidth = 2
        arrowPath.stroke()
    }
}
