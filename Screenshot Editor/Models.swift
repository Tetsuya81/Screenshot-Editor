//
//  Models.swift
//  Screenshot Editor
//
//  Created by Tokunaga Tetsuya on 2025/03/06.
//

import SwiftUI

enum AnnotationTool: String, CaseIterable, Identifiable {
    case highlight = "highlighter"
    case text = "text.cursor"
    case arrow = "arrow.up.right"
    
    var id: String { self.rawValue }
    
    var icon: String {
        rawValue
    }
}

struct Annotation: Identifiable {
    let id = UUID()
    let type: AnnotationTool
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: Color
    let text: String
    let fontSize: CGFloat
}
