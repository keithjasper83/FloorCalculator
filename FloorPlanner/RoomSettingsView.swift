import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
#endif
import simd


//
//  RoomSettingsView.swift
//  FloorPlanner
//
//  View for configuring room dimensions and settings
//


struct RoomSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDesigner = false
    @State private var showARScanner = false
    
    var body: some View {
        Form {
            Section("Room Type") {
                Picker("Shape", selection: $appState.currentProject.roomSettings.shape) {
                    ForEach(RoomShape.allCases, id: \.self) { shape in
                        Text(shape.rawValue).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
                
                if appState.currentProject.roomSettings.shape == .polygon {
                    Button(action: { showDesigner = true }) {
                        HStack {
                            Image(systemName: "pencil.and.ruler")
                            Text("Design Custom Room")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !appState.currentProject.roomSettings.polygonPoints.isEmpty {
                        HStack {
                            Text("Points Defined")
                            Spacer()
                            Text("\(appState.currentProject.roomSettings.polygonPoints.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if appState.currentProject.roomSettings.shape == .rectangular {
                Section("Room Dimensions") {
                    #if os(iOS)
                    Button(action: { showARScanner = true }) {
                        Label("Scan Room with AR", systemImage: "camera.viewfinder")
                    }
                    #endif

                    HStack {
                        Text("Length (mm)")
                        Spacer()
                        TextField("Length", value: $appState.currentProject.roomSettings.lengthMm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Width (mm)")
                        Spacer()
                        TextField("Width", value: $appState.currentProject.roomSettings.widthMm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            
            Section("Expansion Gap") {
                HStack {
                    Text("Expansion Gap (mm)")
                    Spacer()
                    TextField("Gap", value: $appState.currentProject.roomSettings.expansionGapMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section("Installation Pattern") {
                Picker("Pattern", selection: $appState.currentProject.roomSettings.patternType) {
                    ForEach(InstallationPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue).tag(pattern)
                    }
                }
                .pickerStyle(.segmented)

                if appState.currentProject.roomSettings.patternType == .diagonal {
                    VStack {
                        HStack {
                            Text("Angle")
                            Spacer()
                            Text("\(Int(appState.currentProject.roomSettings.angleDegrees))°")
                        }
                        Slider(value: $appState.currentProject.roomSettings.angleDegrees, in: 0...60, step: 1)

                        // Presets
                        HStack {
                            Button("0°") { appState.currentProject.roomSettings.angleDegrees = 0 }
                            Spacer()
                            Button("22.5°") { appState.currentProject.roomSettings.angleDegrees = 22.5 }
                            Spacer()
                            Button("45°") { appState.currentProject.roomSettings.angleDegrees = 45 }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }

            Section("Calculated Areas") {
                HStack {
                    Text("Gross Area")
                    Spacer()
                    Text("\(appState.currentProject.roomSettings.grossAreaM2, specifier: "%.2f") m²")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Usable Area")
                    Spacer()
                    Text("\(appState.currentProject.roomSettings.usableAreaM2, specifier: "%.2f") m²")
                        .foregroundColor(.secondary)
                }
                
                if appState.currentProject.roomSettings.shape == .polygon {
                    HStack {
                        Text("Bounding Box")
                        Spacer()
                        Text("\(Int(appState.currentProject.roomSettings.boundingLengthMm))×\(Int(appState.currentProject.roomSettings.boundingWidthMm))mm")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Waste Factor") {
                HStack {
                    Text("Waste Factor (%)")
                    Spacer()
                    TextField("Waste", value: $appState.currentProject.wasteFactor, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
        }
        .sheet(isPresented: $showDesigner) {
            RoomDesignerView()
        }
        #if os(iOS)
        .sheet(isPresented: $showARScanner) {
            ARCaptureView(roomSettings: $appState.currentProject.roomSettings)
        }
        #endif
    }
}
struct ARCaptureView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var roomSettings: RoomSettings

    var body: some View {
        #if canImport(RoomPlan)
        if #available(iOS 16.0, *), RoomCaptureSession.isSupported {
            RoomCaptureContainer(roomSettings: $roomSettings)
                .edgesIgnoringSafeArea(.all)
        } else {
            fallbackView
        }
        #else
        fallbackView
        #endif
    }

    private var fallbackView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Room Scanning Not Supported")
                .font(.title2)
                .fontWeight(.bold)

            Text("Automatic room scanning requires an iPhone or iPad with a LiDAR scanner (Pro models) and iOS 16+.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#if canImport(RoomPlan)
@available(iOS 16.0, *)
@MainActor
struct RoomCaptureContainer: UIViewRepresentable {
    @Binding var roomSettings: RoomSettings
    @Environment(\.dismiss) var dismiss

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView()
        view.captureSession.delegate = context.coordinator
        view.delegate = context.coordinator

        // Start session safely
        if RoomCaptureSession.isSupported {
            let config = RoomCaptureSession.Configuration()
            view.captureSession.run(configuration: config)
        }

        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // No-op
    }

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: RoomCaptureCoordinator) {
        // Always stop the session when the view is dismantled to prevent ARKit crashes
        uiView.captureSession.stop()
    }

    func makeCoordinator() -> RoomCaptureCoordinator {
        RoomCaptureCoordinator(roomSettings: $roomSettings, dismiss: { [dismiss] in dismiss() })
    }
}
@available(iOS 16.0, *)
@MainActor
final class RoomCaptureCoordinator: NSObject, NSSecureCoding, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    let roomSettings: Binding<RoomSettings>
    let dismissAction: @MainActor () -> Void

    init(roomSettings: Binding<RoomSettings>, dismiss: @escaping @MainActor () -> Void) {
        self.roomSettings = roomSettings
        self.dismissAction = dismiss
        super.init()
    }

    // MARK: - NSSecureCoding (not used, but required for certain Obj-C expectations)
    static var supportsSecureCoding: Bool { true }

    @MainActor required convenience init?(coder: NSCoder) {
        // This coordinator is never expected to be encoded/decoded.
        // Provide a minimal implementation to satisfy protocol requirements.
        // We can't reconstruct required bindings from a coder, so return nil.
        return nil
    }

    func encode(with coder: NSCoder) {
        // No-op: the coordinator holds runtime-only state and should not be archived.
    }

    @MainActor
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }

    @MainActor
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            DiagnosticsManager.shared.log(error: error, context: "RoomPlan capture")
            DispatchQueue.main.async { self.dismissAction() }
            return
        }

        guard !processedResult.walls.isEmpty else {
            DispatchQueue.main.async { self.dismissAction() }
            return
        }

        // Extract each wall's two endpoints in the world XZ plane (Y is height, not floor plan).
        // simd_float2.x = world X, simd_float2.y = world Z.
        var segments: [(simd_float2, simd_float2)] = []
        for wall in processedResult.walls {
            let halfLen = wall.dimensions.x / 2
            let p1w = wall.transform * simd_float4(-halfLen, 0, 0, 1)
            let p2w = wall.transform * simd_float4(halfLen, 0, 0, 1)
            segments.append((simd_float2(p1w.x, p1w.z), simd_float2(p2w.x, p2w.z)))
        }

        // Chain wall segments into an ordered polygon outline.
        let chain = chainWallsToPolygon(segments)

        if chain.count >= 3 {
            // Convert metres → mm and normalise so minimum is at (0, 0).
            let rawPoints = chain.map { RoomPoint(x: Double($0.x) * 1000, y: Double($0.y) * 1000) }
            let minX = rawPoints.map { $0.x }.min() ?? 0
            let minY = rawPoints.map { $0.y }.min() ?? 0
            let polygonPoints = rawPoints.map { RoomPoint(x: $0.x - minX, y: $0.y - minY) }
            let maxX = polygonPoints.map { $0.x }.max() ?? 0
            let maxY = polygonPoints.map { $0.y }.max() ?? 0

            DispatchQueue.main.async {
                self.roomSettings.wrappedValue.shape = .polygon
                self.roomSettings.wrappedValue.polygonPoints = polygonPoints
                self.roomSettings.wrappedValue.lengthMm = maxX
                self.roomSettings.wrappedValue.widthMm = maxY
                self.dismissAction()
            }
        } else {
            // Fallback: bounding-box rectangle if chaining failed.
            var minX: Float = .infinity, minZ: Float = .infinity
            var maxX: Float = -.infinity, maxZ: Float = -.infinity
            for seg in segments {
                minX = min(minX, seg.0.x, seg.1.x)
                minZ = min(minZ, seg.0.y, seg.1.y)
                maxX = max(maxX, seg.0.x, seg.1.x)
                maxZ = max(maxZ, seg.0.y, seg.1.y)
            }
            DispatchQueue.main.async {
                self.roomSettings.wrappedValue.lengthMm = Double(maxX - minX) * 1000
                self.roomSettings.wrappedValue.widthMm = Double(maxZ - minZ) * 1000
                self.roomSettings.wrappedValue.shape = .rectangular
                self.roomSettings.wrappedValue.polygonPoints = []
                self.dismissAction()
            }
        }
    }
}

/// Greedy segment-chaining algorithm that orders wall endpoint pairs into a polygon.
///
/// Each wall provides two endpoints. We greedily find the next segment whose nearer
/// endpoint connects to the current chain tip (within `tolerance` metres), appending
/// the far endpoint. Duplicate closing vertices are removed.
@available(iOS 16.0, *)
private func chainWallsToPolygon(_ segments: [(simd_float2, simd_float2)]) -> [simd_float2] {
    guard !segments.isEmpty else { return [] }

    // Tolerance for considering two endpoints "the same corner" (150 mm = 0.15 m)
    let tolerance: Float = 0.15

    var remaining = segments
    var chain = [remaining[0].0, remaining[0].1]
    remaining.removeFirst()

    while !remaining.isEmpty {
        let tip = chain.last!
        var bestIndex = -1
        var bestDist = tolerance
        // true  → seg.0 matched tip, so add seg.1 as next vertex
        // false → seg.1 matched tip, so add seg.0 as next vertex
        var useP2AsNext = false

        for (i, seg) in remaining.enumerated() {
            let d0 = hypot(tip.x - seg.0.x, tip.y - seg.0.y)
            let d1 = hypot(tip.x - seg.1.x, tip.y - seg.1.y)
            // Pick whichever endpoint of this segment is closer to tip
            let (closerDist, addP2) = d0 <= d1 ? (d0, true) : (d1, false)
            if closerDist < bestDist {
                bestDist = closerDist
                bestIndex = i
                useP2AsNext = addP2
            }
        }

        guard bestIndex >= 0 else { break }
        let seg = remaining[bestIndex]
        chain.append(useP2AsNext ? seg.1 : seg.0)
        remaining.remove(at: bestIndex)
    }

    // Drop the closing vertex if it's the same as the first (polygon is implicitly closed).
    if chain.count > 1 && hypot(chain[0].x - chain.last!.x, chain[0].y - chain.last!.y) < tolerance {
        chain.removeLast()
    }

    return chain
}

#endif
struct RoomDesignerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var points: [RoomPoint] = []
    @State private var currentPoint: CGPoint? = nil
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var gridSize: Double = 500 // mm per grid square
    @State private var showDimensionInput = false
    @State private var selectedSegmentIndex: Int? = nil
    @State private var editingDimension: String = ""
    @State private var showConfirmation = false
    @State private var isClosed: Bool = false

    private let gridColor = Color.gray.opacity(0.3)
    private let pointColor = Color.blue
    private let lineColor = Color.blue
    private let closePolygonTapThreshold: CGFloat = 25
    private let closeTargetRingRadius: CGFloat = 14

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toolbar
                toolbarView

                // Canvas
                GeometryReader { geometry in
                    ZStack {
                        // Grid background
                        Canvas { context, size in
                            drawGrid(context: context, size: size)
                            drawRoom(context: context, size: size)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !showDimensionInput {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(3.0, value))
                                }
                        )
                        .onTapGesture { location in
                            handleTap(at: location, in: geometry.size)
                        }
                    }
                }
                .background(Color(white: 0.95))

                // Instructions
                instructionsView
            }
            .navigationTitle("Room Designer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if (isClosed && points.count >= 3) || appState.currentProject.roomSettings.shape != .polygon {
                            showConfirmation = true
                        }
                    }
                    .disabled(!(isClosed && points.count >= 3))
                }
            }
            .alert("Apply Room Design?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Apply") {
                    applyDesign()
                }
            } message: {
                Text("This will replace the current room configuration with your custom design.")
            }
            .sheet(isPresented: $showDimensionInput) {
                dimensionInputSheet
            }
        }
    }

    private var toolbarView: some View {
        HStack {
            Button(action: clearAll) {
                Label("Clear", systemImage: "trash")
            }

            Spacer()

            if points.count >= 3 {
                Button(action: { isClosed.toggle() }) {
                    Label(isClosed ? "Open Shape" : "Close Shape", systemImage: isClosed ? "xmark.circle" : "checkmark.circle")
                }
                .foregroundColor(isClosed ? .orange : .green)
            }

            Spacer()

            Button(action: undoLastPoint) {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(points.isEmpty)
        }
        .padding()
        .background(Color(white: 0.9))
    }

    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if points.isEmpty {
                Text("Tap to place the first corner point")
                    .font(.subheadline)
            } else if points.count == 1 {
                Text("Tap to place the second point and create a wall")
                    .font(.subheadline)
            } else if points.count < 3 {
                Text("Continue tapping to add more walls")
                    .font(.subheadline)
            } else {
                Text(isClosed ? "Shape is closed. You can edit or press Done to apply" : "Tap the first point (green) to close the shape, or use 'Close Shape'")
                    .font(.subheadline)
            }

            HStack {
                Text("Points: \(points.count)")
                Spacer()
                Text("Grid: \(Int(gridSize))mm")
                Spacer()
                Text("Zoom: \(scale, specifier: "%.1f")x")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(white: 0.9))
    }

    private var dimensionInputSheet: some View {
        NavigationStack {
            Form {
                Section("Adjust Dimension") {
                    TextField("Distance (mm)", text: $editingDimension)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Dimension")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDimensionInput = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyDimension()
                    }
                }
            }
        }
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2 + offset.width
        let centerY = size.height / 2 + offset.height

        let scaledGridSize = gridSize * scale / 10.0 // Scale grid to reasonable pixel size

        // Draw vertical lines
        var x = centerX
        while x < size.width {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(gridColor),
                lineWidth: 1
            )
            x += scaledGridSize
        }

        x = centerX - scaledGridSize
        while x > 0 {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(gridColor),
                lineWidth: 1
            )
            x -= scaledGridSize
        }

        // Draw horizontal lines
        var y = centerY
        while y < size.height {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(gridColor),
                lineWidth: 1
            )
            y += scaledGridSize
        }

        y = centerY - scaledGridSize
        while y > 0 {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(gridColor),
                lineWidth: 1
            )
            y -= scaledGridSize
        }
    }

    private func drawRoom(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2 + offset.width
        let centerY = size.height / 2 + offset.height

        // Convert mm to pixels (1mm = 0.1 pixels at scale 1.0)
        let mmToPixels: Double = 0.1 * scale

        // Draw lines between points
        if points.count >= 2 {
            for i in 0..<points.count {
                let start = points[i]
                let end = points[(i + 1) % points.count]

                let startPoint = CGPoint(
                    x: centerX + start.x * mmToPixels,
                    y: centerY + start.y * mmToPixels
                )
                let endPoint = CGPoint(
                    x: centerX + end.x * mmToPixels,
                    y: centerY + end.y * mmToPixels
                )

                // Draw line segment (skip closing segment unless polygon is explicitly closed)
                if i < points.count - 1 || (isClosed && points.count >= 3 && i == points.count - 1) {
                    context.stroke(
                        Path { path in
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        },
                        with: .color(lineColor),
                        lineWidth: 3
                    )

                    // Draw dimension label
                    let dx = end.x - start.x
                    let dy = end.y - start.y
                    let distance = sqrt(dx * dx + dy * dy)
                    let midPoint = CGPoint(
                        x: (startPoint.x + endPoint.x) / 2,
                        y: (startPoint.y + endPoint.y) / 2
                    )

                    context.draw(
                        Text("\(Int(distance))mm")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue),
                        at: midPoint
                    )
                }
            }
        }

        // Draw points
        for (index, point) in points.enumerated() {
            let screenPoint = CGPoint(
                x: centerX + point.x * mmToPixels,
                y: centerY + point.y * mmToPixels
            )

            // Highlight the first point in green when 3+ points exist and shape is open,
            // indicating the user can tap it to close the polygon.
            let isCloseTarget = index == 0 && points.count >= 3 && !isClosed
            let fillColor: Color = isCloseTarget ? .green : pointColor

            if isCloseTarget {
                // Draw a larger ring around the first point as a close-target indicator
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: screenPoint.x - closeTargetRingRadius,
                        y: screenPoint.y - closeTargetRingRadius,
                        width: closeTargetRingRadius * 2,
                        height: closeTargetRingRadius * 2
                    )),
                    with: .color(.green.opacity(0.6)),
                    lineWidth: 2
                )
            }

            context.fill(
                Path(ellipseIn: CGRect(
                    x: screenPoint.x - 6,
                    y: screenPoint.y - 6,
                    width: 12,
                    height: 12
                )),
                with: .color(fillColor)
            )

            context.stroke(
                Path(ellipseIn: CGRect(
                    x: screenPoint.x - 6,
                    y: screenPoint.y - 6,
                    width: 12,
                    height: 12
                )),
                with: .color(.white),
                lineWidth: 2
            )
        }

        // Draw current/preview point
        if let current = currentPoint {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: current.x - 4,
                    y: current.y - 4,
                    width: 8,
                    height: 8
                )),
                with: .color(pointColor.opacity(0.5))
            )
        }
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        let centerX = size.width / 2 + offset.width
        let centerY = size.height / 2 + offset.height

        // Convert tap location to mm coordinates
        let mmToPixels: Double = 0.1 * scale
        let x = (location.x - centerX) / mmToPixels
        let y = (location.y - centerY) / mmToPixels

        // Snap to grid
        let snappedX = round(x / gridSize) * gridSize
        let snappedY = round(y / gridSize) * gridSize

        if isClosed { return }

        // Close polygon by tapping near the first point (standard polygon-drawing UX)
        if points.count >= 3 {
            let firstPoint = points[0]
            let firstScreenPoint = CGPoint(
                x: centerX + firstPoint.x * mmToPixels,
                y: centerY + firstPoint.y * mmToPixels
            )
            let distToFirst = hypot(location.x - firstScreenPoint.x, location.y - firstScreenPoint.y)
            if distToFirst < closePolygonTapThreshold {
                isClosed = true
                return
            }
        }

        if points.count >= 2 {
            let tapPoint = CGPoint(x: location.x, y: location.y)
            for i in 0..<(isClosed ? points.count : points.count - 1) {
                let a = points[i]
                let b = points[(i + 1) % points.count]
                let aPt = CGPoint(x: centerX + a.x * mmToPixels, y: centerY + a.y * mmToPixels)
                let bPt = CGPoint(x: centerX + b.x * mmToPixels, y: centerY + b.y * mmToPixels)
                let dist = distancePointToSegment(p: tapPoint, a: aPt, b: bPt)
                if dist < 20 {
                    selectedSegmentIndex = i
                    editingDimension = String(Int(hypot(b.x - a.x, b.y - a.y)))
                    showDimensionInput = true
                    return
                }
            }
        }

        // Add point
        let newPoint = RoomPoint(x: snappedX, y: snappedY)

        // Check if point is too close to existing points
        let tooClose = points.contains { point in
            let dx = point.x - snappedX
            let dy = point.y - snappedY
            return sqrt(dx * dx + dy * dy) < gridSize / 4
        }

        if !tooClose {
            points.append(newPoint)
        }
    }

    private func undoLastPoint() {
        if !points.isEmpty {
            points.removeLast()
            isClosed = false
        }
    }

    private func clearAll() {
        points.removeAll()
        scale = 1.0
        offset = .zero
        lastOffset = .zero
        isClosed = false
    }

    private func closePolygon() {
        if points.count >= 3 {
            isClosed = true
        }
    }

    private func applyDimension() {
        guard let idx = selectedSegmentIndex,
              let newLen = Double(editingDimension),
              points.indices.contains(idx),
              points.indices.contains((idx + 1) % points.count) else {
            showDimensionInput = false
            return
        }

        var a = points[idx]
        var b = points[(idx + 1) % points.count]

        let dx = b.x - a.x
        let dy = b.y - a.y
        let currentLen = sqrt(dx*dx + dy*dy)
        guard currentLen > 0 else {
            showDimensionInput = false
            return
        }

        let scale = newLen / currentLen
        let newB = RoomPoint(x: a.x + dx * scale, y: a.y + dy * scale)
        points[(idx + 1) % points.count] = newB

        showDimensionInput = false
    }

    private func applyDesign() {
        guard isClosed && points.count >= 3 else {
            // Fall back to existing settings if not a valid closed polygon
            dismiss()
            return
        }

        // Convert points to room settings
        appState.currentProject.roomSettings.shape = .polygon

        if points.isEmpty {
            // No points: save an empty polygon and leave existing dimensions unchanged
            appState.currentProject.roomSettings.polygonPoints = []
        } else {
            // Normalize polygon so its minimum coordinate is at (0, 0)
            let minX = points.map { $0.x }.min() ?? 0
            let minY = points.map { $0.y }.min() ?? 0

            let translatedPoints = points.map { point in
                RoomPoint(x: point.x - minX, y: point.y - minY)
            }

            appState.currentProject.roomSettings.polygonPoints = translatedPoints

            // Update bounding box dimensions for backward compatibility
            let maxX = translatedPoints.map { $0.x }.max() ?? 0
            let maxY = translatedPoints.map { $0.y }.max() ?? 0

            appState.currentProject.roomSettings.lengthMm = maxX
            appState.currentProject.roomSettings.widthMm = maxY
        }

        appState.saveProject()
        dismiss()
    }

    private func distancePointToSegment(p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let ap = CGPoint(x: p.x - a.x, y: p.y - a.y)
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let abLen2 = ab.x * ab.x + ab.y * ab.y
        if abLen2 == 0 { return hypot(ap.x, ap.y) }
        let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / abLen2))
        let proj = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
        return hypot(p.x - proj.x, p.y - proj.y)
    }
}

