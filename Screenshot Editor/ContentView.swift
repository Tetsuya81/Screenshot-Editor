//
//  ContentView.swift
//  Screenshot Editor
//
//  Created by Tokunaga Tetsuya on 2025/03/06.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var dragStartPoint: CGPoint?
    @State private var currentDragPoint: CGPoint?
    
    var body: some View {
        if screenshotManager.isEditing, let screenshot = screenshotManager.currentScreenshot {
            EditorView(screenshot: screenshot)
        } else {
            HomeView()
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("Screenshot Tool")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button(action: {
                    screenshotManager.captureFullScreen()
                }) {
                    HStack {
                        Image(systemName: "rectangle.dashed")
                        Text("Capture Full Screen")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    screenshotManager.captureSelectedArea()
                }) {
                    HStack {
                        Image(systemName: "crop")
                        Text("Capture Selected Area")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Text("Hotkeys:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("⌘ + ⇧ + 1")
                        .fontWeight(.bold)
                    Text("Full Screen")
                }
                
                HStack {
                    Text("⌘ + ⇧ + 2")
                        .fontWeight(.bold)
                    Text("Selected Area")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct EditorView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var dragStartPoint: CGPoint?
    @State private var isEditing = false
    let screenshot: NSImage
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(AnnotationTool.allCases) { tool in
                    Button(action: {
                        screenshotManager.selectedTool = tool
                    }) {
                        Image(systemName: tool.icon)
                            .frame(width: 30, height: 30)
                            .foregroundColor(screenshotManager.selectedTool == tool ? .blue : .gray)
                            .background(screenshotManager.selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                
                ColorPicker("", selection: $screenshotManager.selectedColor)
                    .labelsHidden()
                    .frame(width: 30)
                
                Spacer()
                
                if screenshotManager.selectedTool == .text {
                    TextField("Text to add", text: $screenshotManager.textInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    
                    Stepper("Font: \(Int(screenshotManager.fontsize))", value: $screenshotManager.fontsize, in: 8...72, step: 2)
                        .frame(width: 150)
                }
                
                Spacer()
                
                Button(action: {
                    screenshotManager.saveScreenshot()
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    screenshotManager.isEditing = false
                }) {
                    Image(systemName: "xmark")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            
            ZStack {
                Image(nsImage: screenshot)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if dragStartPoint == nil {
                                    dragStartPoint = value.startLocation
                                }
                                
                                if screenshotManager.selectedTool == .text {
                                    // For text, we only care about the click position
                                    if !isEditing {
                                        isEditing = true
                                    }
                                } else {
                                    // For other tools, we track dragging
                                    if !isEditing {
                                        isEditing = true
                                    }
                                }
                            }
                            .onEnded { value in
                                defer {
                                    dragStartPoint = nil
                                    isEditing = false
                                }
                                
                                guard let startPoint = dragStartPoint else { return }
                                
                                switch screenshotManager.selectedTool {
                                case .highlight:
                                    screenshotManager.addHighlightAnnotation(from: startPoint, to: value.location)
                                case .text:
                                    screenshotManager.addTextAnnotation(at: startPoint)
                                case .arrow:
                                    screenshotManager.addArrowAnnotation(from: startPoint, to: value.location)
                                }
                            }
                    )
                
                // Draw existing annotations
                ForEach(screenshotManager.annotations) { annotation in
                    AnnotationView(annotation: annotation)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
    }
}

struct AnnotationView: View {
    let annotation: Annotation
    
    var body: some View {
        switch annotation.type {
        case .highlight:
            Rectangle()
                .fill(annotation.color.opacity(0.3))
                .frame(
                    width: abs(annotation.endPoint.x - annotation.startPoint.x),
                    height: abs(annotation.endPoint.y - annotation.startPoint.y)
                )
                .border(annotation.color, width: 2)
                .position(
                    x: (annotation.startPoint.x + annotation.endPoint.x) / 2,
                    y: (annotation.startPoint.y + annotation.endPoint.y) / 2
                )
        case .text:
            Text(annotation.text)
                .font(.system(size: annotation.fontSize))
                .foregroundColor(annotation.color)
                .position(annotation.startPoint)
        case .arrow:
            ArrowShape(start: annotation.startPoint, end: annotation.endPoint)
                .stroke(annotation.color, lineWidth: 2)
        }
    }
}

struct ArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = CGFloat.pi / 8
        
        path.move(to: start)
        path.addLine(to: end)
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.move(to: end)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

#Preview {
    ContentView()
}
