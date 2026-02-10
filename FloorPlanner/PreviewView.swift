//
//  PreviewView.swift
//  FloorPlanner
//
//  2D plan preview with zoom and pan
//

import SwiftUI

struct PreviewView: View {
    @EnvironmentObject var appState: AppState
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            if let result = appState.layoutResult {
                ZStack {
                    // Canvas for drawing
                    Canvas { context, size in
                        drawLayout(context: context, size: size, result: result)
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    
                    // Legend overlay
                    VStack {
                        Spacer()
                        HStack {
                            legendView
                            Spacer()
                        }
                        .padding()
                    }
                }
                
                // Controls
                HStack {
                    Button("Fit") {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                    
                    Spacer()
                    
                    Text("Zoom: \(scale, specifier: "%.1f")x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        exportImage()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
                .padding()
            } else {
                Text("No layout generated")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Preview")
    }
    
    private func drawLayout(context: GraphicsContext, size: CGSize, result: LayoutResult) {
        let room = appState.currentProject.roomSettings
        
        // Calculate scale to fit
        let marginPx = 40.0
        let availableWidth = size.width - 2 * marginPx
        let availableHeight = size.height - 2 * marginPx
        
        let scaleX = availableWidth / room.boundingLengthMm
        let scaleY = availableHeight / room.boundingWidthMm
        let baseScale = min(scaleX, scaleY) * scale
        
        let roomWidthPx = room.boundingLengthMm * baseScale
        let roomHeightPx = room.boundingWidthMm * baseScale
        
        let originX = (size.width - roomWidthPx) / 2 + offset.width
        let originY = (size.height - roomHeightPx) / 2 + offset.height
        
        // Draw room outline based on shape
        if room.shape == .rectangular {
            // Draw rectangular room
            let roomRect = CGRect(x: originX, y: originY, width: roomWidthPx, height: roomHeightPx)
            context.stroke(
                Path(roomRect),
                with: .color(.gray),
                lineWidth: 2
            )
            
            // Draw usable area
            let gapPx = room.expansionGapMm * baseScale
            let usableRect = CGRect(
                x: originX + gapPx,
                y: originY + gapPx,
                width: room.usableLengthMm * baseScale,
                height: room.usableWidthMm * baseScale
            )
            context.stroke(
                Path(usableRect),
                with: .color(.blue.opacity(0.5)),
                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
            )
        } else {
            // Draw polygon room
            if !room.polygonPoints.isEmpty {
                // Find min coordinates to normalize
                let minX = room.polygonPoints.map { $0.x }.min() ?? 0
                let minY = room.polygonPoints.map { $0.y }.min() ?? 0
                
                // Draw polygon outline
                var path = Path()
                for (index, point) in room.polygonPoints.enumerated() {
                    let x = originX + (point.x - minX) * baseScale
                    let y = originY + (point.y - minY) * baseScale
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
                
                context.stroke(
                    path,
                    with: .color(.gray),
                    lineWidth: 2
                )
                
                // Draw points
                for point in room.polygonPoints {
                    let x = originX + (point.x - minX) * baseScale
                    let y = originY + (point.y - minY) * baseScale
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8)),
                        with: .color(.blue)
                    )
                }
            }
        }
        
        // Draw placed pieces
        for piece in result.placedPieces {
            let gapPx = room.expansionGapMm * baseScale
            let x = originX + gapPx + piece.x * baseScale
            let y = originY + gapPx + piece.y * baseScale
            let width = piece.lengthMm * baseScale
            let height = piece.widthMm * baseScale
            
            let rect = CGRect(x: x, y: y, width: width, height: height)
            let path = Path(rect)
            
            // Color based on status
            let fillColor: Color
            let strokeColor: Color
            let strokeStyle: StrokeStyle
            
            switch piece.status {
            case .installed:
                fillColor = .green.opacity(0.3)
                strokeColor = .green
                strokeStyle = StrokeStyle(lineWidth: 1)
            case .needed:
                fillColor = .red.opacity(0.2)
                strokeColor = .red
                strokeStyle = StrokeStyle(lineWidth: 1, dash: [3, 3])
            }
            
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(strokeColor), style: strokeStyle)
            
            // Draw label if piece is large enough
            if width > 30 && height > 15 {
                let labelPoint = CGPoint(x: x + width / 2, y: y + height / 2)
                context.draw(
                    Text(piece.label)
                        .font(.system(size: 8))
                        .foregroundColor(.primary),
                    at: labelPoint
                )
            }
        }
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Rectangle()
                            .stroke(Color.green, lineWidth: 1)
                    )
                Text("Installed")
                    .font(.caption)
            }
            
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Rectangle()
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
                Text("Needed")
                    .font(.caption)
            }
            
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Rectangle()
                            .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    )
                Text("Usable Area")
                    .font(.caption)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.colorInvert().opacity(0.9))
        )
    }
    
    private func exportImage() {
        // TODO: Implement export
        print("Export image")
    }
}
