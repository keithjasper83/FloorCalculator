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
        
        // Guard against zero/invalid bounds to avoid NaN/inf in scale calculations
        guard availableWidth > 0,
              availableHeight > 0,
              room.boundingLengthMm > 0,
              room.boundingWidthMm > 0 else {
            // Invalid geometry or canvas; render empty state
            return
        }
        
        let scaleX = availableWidth / room.boundingLengthMm
        let scaleY = availableHeight / room.boundingWidthMm
        let baseScale = min(scaleX, scaleY) * scale
        
        let roomWidthPx = room.boundingLengthMm * baseScale
        let roomHeightPx = room.boundingWidthMm * baseScale
        
        let originX = (size.width - roomWidthPx) / 2 + offset.width
        let originY = (size.height - roomHeightPx) / 2 + offset.height
        
        // Determine room path
        var roomPath = Path()
        if room.shape == .rectangular {
             let roomRect = CGRect(x: originX, y: originY, width: roomWidthPx, height: roomHeightPx)
             roomPath = Path(roomRect)
        } else if !room.polygonPoints.isEmpty {
             let minX = room.polygonPoints.map { $0.x }.min() ?? 0
             let minY = room.polygonPoints.map { $0.y }.min() ?? 0

             roomPath.move(to: CGPoint(x: originX, y: originY)) // Start

             for (index, point) in room.polygonPoints.enumerated() {
                 let x = originX + (point.x - minX) * baseScale
                 let y = originY + (point.y - minY) * baseScale

                 if index == 0 {
                     roomPath.move(to: CGPoint(x: x, y: y))
                 } else {
                     roomPath.addLine(to: CGPoint(x: x, y: y))
                 }
             }
             roomPath.closeSubpath()
        }

        // Draw room outline
        context.stroke(roomPath, with: .color(.gray), lineWidth: 2)

        // Draw Usable Area Outline (inset by gap)
        // Note: Accurately insetting arbitrary polygon is complex.
        // For rectangle it's easy. For polygon, we approximate or skip if complex.
        // For continuous material, we might just fill the room path if gap is negligible visually or handled elsewhere.
        // But let's try to draw the gap line for context.

        if room.shape == .rectangular {
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
        }

        // Draw Content
        if !result.placedPieces.isEmpty {
            // Draw discrete pieces
            for piece in result.placedPieces {
                let gapPx = room.expansionGapMm * baseScale
                let x = originX + gapPx + piece.x * baseScale
                let y = originY + gapPx + piece.y * baseScale
                let width = piece.lengthMm * baseScale
                let height = piece.widthMm * baseScale
                
                // Handle rotation
                let centerX = x + width / 2
                let centerY = y + height / 2

                // Create path centered at 0,0
                let centeredRect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
                let rectPath = Path(centeredRect)

                // Apply rotation and translation using context transform is easier if we push/pop,
                // but Swift Canvas uses context.withCGContext or purely Path transforms.
                // Path transform:
                let transform = CGAffineTransform(rotationAngle: piece.rotation * .pi / 180.0)
                    .concatenating(CGAffineTransform(translationX: centerX, y: centerY))

                let path = rectPath.applying(transform)

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
                     // Swift Canvas text drawing is simple
                     let text = Text(piece.label)
                         .font(.system(size: 8))
                         .foregroundColor(.primary)
                     context.draw(text, at: CGPoint(x: centerX, y: centerY))
                }
            }
        } else if result.installedAreaM2 > 0 {
             // Continuous material fill
             // Fill the usable area (or room area if simple)
             // Determine color based on material type
             let materialType = appState.currentProject.materialType
             var fillColor: Color = .gray.opacity(0.3)

             switch materialType {
             case .concrete: fillColor = .gray.opacity(0.5)
             case .paint: fillColor = .blue.opacity(0.3)
             case .plasterboard: fillColor = .white.opacity(0.8) // Might be invisible on white bg, check scheme
             default: fillColor = .green.opacity(0.3)
             }

             // If Rectangular, fill usable rect
             if room.shape == .rectangular {
                 let gapPx = room.expansionGapMm * baseScale
                 let usableRect = CGRect(
                     x: originX + gapPx,
                     y: originY + gapPx,
                     width: room.usableLengthMm * baseScale,
                     height: room.usableWidthMm * baseScale
                 )
                 context.fill(Path(usableRect), with: .color(fillColor))

                 // Add label in center
                 context.draw(Text(materialType.rawValue), at: CGPoint(x: originX + roomWidthPx/2, y: originY + roomHeightPx/2))
             } else {
                 // For polygon, filling the room path (ignoring gap for simple preview)
                 context.fill(roomPath, with: .color(fillColor))
                 context.draw(Text(materialType.rawValue), at: CGPoint(x: originX + roomWidthPx/2, y: originY + roomHeightPx/2))
             }
        }
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if appState.currentProject.materialType.toDomainMaterial.calculationType == .discrete {
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
            } else {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5)) // Generic fill for legend
                        .frame(width: 20, height: 20)
                    Text("Coverage Area")
                        .font(.caption)
                }
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
                .fill(.regularMaterial)
        )
    }
    
    private func exportImage() {
        // TODO: Implement export
        print("Export image")
    }
}
