import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
#endif
import simd

// MARK: - Floor plan helpers
#if canImport(RoomPlan)
/// Simple 2D point on the floor plane used for chaining wall segments (x = world X, y = world Z).
/// Defined here (app target) because WallChaining.swift is only compiled in the Swift Package target.
struct FloorPoint: Hashable {
    var x: Float
    var y: Float

    init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }
}

/// Chains unordered wall-endpoint segments into an ordered polygon path.
/// Greedily connects nearest endpoints until the polygon closes or no matching endpoint remains.
private func chainWallSegments(_ segments: [(FloorPoint, FloorPoint)]) -> [FloorPoint] {
    guard !segments.isEmpty else { return [] }

    var remaining = segments
    var current = remaining.removeFirst().0
    var path: [FloorPoint] = [current]

    func dist2(_ a: FloorPoint, _ b: FloorPoint) -> Float {
        let dx = a.x - b.x; let dy = a.y - b.y
        return dx*dx + dy*dy
    }

    let maxIter = segments.count * 4
    for _ in 0..<maxIter {
        guard !remaining.isEmpty else { break }
        var bestIdx: Int?
        var bestNext: FloorPoint?
        var bestScore: Float = .infinity

        for (idx, seg) in remaining.enumerated() {
            let d0 = dist2(current, seg.0)
            let d1 = dist2(current, seg.1)
            if d0 < bestScore { bestScore = d0; bestNext = seg.1; bestIdx = idx }
            if d1 < bestScore { bestScore = d1; bestNext = seg.0; bestIdx = idx }
        }

        guard let idx = bestIdx, let next = bestNext else { break }
        current = next
        path.append(current)
        remaining.remove(at: idx)
        if path.count >= 3, dist2(current, path[0]) < 0.01 { break }
    }

    if path.count >= 2, path.first == path.last { path.removeLast() }
    return path
}
#endif


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
            RoomDesignerView(initialPoints: appState.currentProject.roomSettings.polygonPoints)
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
final class RoomCaptureCoordinator: NSObject, @preconcurrency NSSecureCoding, @preconcurrency RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

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
            dismissAction()
            return
        }

        guard !processedResult.walls.isEmpty else {
            dismissAction()
            return
        }

        // Extract each wall's two endpoints in the world XZ plane (Y is height, not floor plan).
        var segments: [(FloorPoint, FloorPoint)] = []
        for wall in processedResult.walls {
            let halfLen = wall.dimensions.x / 2
            let p1w = wall.transform * simd_float4(-halfLen, 0, 0, 1)
            let p2w = wall.transform * simd_float4(halfLen, 0, 0, 1)
            segments.append((FloorPoint(p1w.x, p1w.z), FloorPoint(p2w.x, p2w.z)))
        }

        // Chain wall segments into an ordered polygon outline.
        let chain = chainWallSegments(segments)

        if chain.count >= 3 {
            // Convert metres → mm and normalise so minimum is at (0, 0).
            let rawPoints = chain.map { RoomPoint(x: Double($0.x) * 1000, y: Double($0.y) * 1000) }
            let minX = rawPoints.map { $0.x }.min() ?? 0
            let minY = rawPoints.map { $0.y }.min() ?? 0
            let polygonPoints = rawPoints.map { RoomPoint(x: $0.x - minX, y: $0.y - minY) }
            let maxX = polygonPoints.map { $0.x }.max() ?? 0
            let maxY = polygonPoints.map { $0.y }.max() ?? 0

            roomSettings.wrappedValue.shape = .polygon
            roomSettings.wrappedValue.polygonPoints = polygonPoints
            roomSettings.wrappedValue.lengthMm = maxX
            roomSettings.wrappedValue.widthMm = maxY
            dismissAction()
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
            roomSettings.wrappedValue.lengthMm = Double(maxX - minX) * 1000
            roomSettings.wrappedValue.widthMm = Double(maxZ - minZ) * 1000
            roomSettings.wrappedValue.shape = .rectangular
            roomSettings.wrappedValue.polygonPoints = []
            dismissAction()
        }
    }
}

#endif
struct RoomDesignerView: View {
    private enum DimensionEditMode: String, CaseIterable, Identifiable {
        case preserveShape = "Preserve Shape"
        case moveSingleCorner = "Move One Corner"

        var id: String { rawValue }
    }

    private enum AngleConstraintMode: String, CaseIterable, Identifiable {
        case free = "Free"
        case deg45 = "45°"
        case deg90 = "90°"
        case deg135 = "135°"
        case deg180 = "180°"

        var id: String { rawValue }

        var angleDegrees: Double? {
            switch self {
            case .free: return nil
            case .deg45: return 45
            case .deg90: return 90
            case .deg135: return 135
            case .deg180: return 180
            }
        }
    }

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var points: [RoomPoint]
    @State private var currentPoint: CGPoint? = nil
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var gridSize: Double = 500 // mm per grid square
    @State private var showDimensionInput = false
    @State private var selectedSegmentIndex: Int? = nil
    @State private var editingDimension: String = ""
    @State private var dimensionEditMode: DimensionEditMode = .preserveShape
    @State private var angleConstraintMode: AngleConstraintMode = .free
    @State private var draggedPointIndex: Int? = nil
    @State private var lockedCornerIndices: Set<Int> = []
    @State private var dimensionEditErrorMessage: String?
    @State private var showDimensionEditError = false
    @State private var showConfirmation = false
    @State private var isClosed: Bool

    init(initialPoints: [RoomPoint] = []) {
        _points = State(initialValue: initialPoints)
        _isClosed = State(initialValue: initialPoints.count >= 3)
    }

    private let gridColor = Color.gray.opacity(0.22)
    private let pointColor = Color(red: 0.08, green: 0.16, blue: 0.28)
    private let lineColor = Color.black
    private let lockedColor = Color.orange
    private let extensionLineColor = Color.gray.opacity(0.65)
    private let dimensionLineColor = Color(red: 0.1, green: 0.2, blue: 0.45)
    private let dimensionOffsetBase: CGFloat = 26
    private let dimensionOffsetStep: CGFloat = 14
    private let extensionLeadIn: CGFloat = 8
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
                                    handleCanvasDragChanged(value: value, in: geometry.size)
                                }
                                .onEnded { _ in
                                    handleCanvasDragEnded()
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

                // Wall dimensions panel (shown when 2+ points exist)
                if points.count >= 2 {
                    wallDimensionsList
                }

                if points.count >= 3 {
                    cornerConstraintList
                }

                angleConstraintBar

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
            .alert("Unable to Apply Dimension", isPresented: $showDimensionEditError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dimensionEditErrorMessage ?? "This edit would violate a locked corner constraint.")
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
                Text(isClosed ? "Shape closed · tap a wall button above or a wall on the canvas to edit its length" : "Tap the first point (green) to close the shape, or use 'Close Shape'")
                    .font(.subheadline)
            }

            HStack {
                Text("Points: \(points.count)")
                Spacer()
                Text("Grid: \(Int(gridSize))mm")
                Spacer()
                Text("Angle Lock: \(angleConstraintMode.rawValue)")
                Spacer()
                Text("Zoom: \(scale, specifier: "%.1f")x")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(white: 0.9))
    }

    private var angleConstraintBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Line Angle Lock")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Relative to previous point")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AngleConstraintMode.allCases) { mode in
                        let selected = angleConstraintMode == mode
                        Button {
                            angleConstraintMode = mode
                        } label: {
                            Text(mode.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected ? Color.teal.opacity(0.20) : Color.teal.opacity(0.08))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.teal.opacity(selected ? 0.55 : 0.35), lineWidth: 1)
                                )
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(white: 0.92))
    }

    // Wall dimensions panel – horizontal scroll of edit buttons for each wall segment
    @ViewBuilder
    private var wallDimensionsList: some View {
        let wallCount = isClosed ? points.count : max(0, points.count - 1)
        if wallCount > 0 {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Wall Dimensions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Tap to edit")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<wallCount, id: \.self) { i in
                            let a = points[i]
                            let b = points[(i + 1) % points.count]
                            let length = sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
                            let roundedLength = Int(length.rounded())
                            let isWallLocked = lockedCornerIndices.contains(i) || lockedCornerIndices.contains((i + 1) % points.count)
                            Button {
                                selectedSegmentIndex = i
                                editingDimension = String(roundedLength)
                                showDimensionInput = true
                            } label: {
                                wallDimensionChip(index: i, length: roundedLength, isWallLocked: isWallLocked)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(white: 0.92))
        }
    }

    private func wallDimensionChip(index: Int, length: Int, isWallLocked: Bool) -> some View {
        let isSelected = selectedSegmentIndex == index
        let chipBackground: Color
        if isSelected {
            chipBackground = isWallLocked ? Color.orange.opacity(0.2) : Color.blue.opacity(0.18)
        } else {
            chipBackground = isWallLocked ? Color.orange.opacity(0.12) : Color.blue.opacity(0.08)
        }
        let strokeColor = isWallLocked ? Color.orange.opacity(0.5) : Color.blue.opacity(0.4)

        return VStack(spacing: 2) {
            HStack(spacing: 3) {
                Text("W\(index + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if isWallLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            HStack(spacing: 2) {
                Text("\(length) mm")
                    .font(.caption)
                    .fontWeight(.semibold)
                Image(systemName: "pencil")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var cornerConstraintList: some View {
        if points.count >= 3 {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Corner Constraints")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Lock angle/position")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<points.count, id: \.self) { i in
                            let isLocked = lockedCornerIndices.contains(i)
                            Button {
                                toggleCornerLock(i)
                            } label: {
                                HStack(spacing: 4) {
                                    Text("C\(i + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                                        .font(.caption)
                                    Text(isLocked ? "Locked" : "Free")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isLocked ? Color.orange.opacity(0.2) : Color.orange.opacity(0.08))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(white: 0.92))
        }
    }

    private var dimensionInputSheet: some View {
        NavigationStack {
            Form {
                if let idx = selectedSegmentIndex,
                   idx < points.count,
                   points.count >= 2 {
                    let a = points[idx]
                    let b = points[(idx + 1) % points.count]
                    let currentLen = Int(sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2)).rounded())
                    Section("Wall \(idx + 1) — Current Length") {
                        HStack {
                            Text("Length")
                            Spacer()
                            Text("\(currentLen) mm")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section("New Length (mm)") {
                    TextField("Enter length in mm", text: $editingDimension)
                        .keyboardType(.decimalPad)
                }

                Section("Edit Behavior") {
                    Picker("Mode", selection: $dimensionEditMode) {
                        ForEach(DimensionEditMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if dimensionEditMode == .preserveShape {
                        Text("Moves downstream corners together so existing angles are preserved. Unlocked final wall is derived.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Moves only one corner. Adjacent angles may change.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(selectedSegmentIndex.map { "Edit Wall \($0 + 1)" } ?? "Edit Dimension")
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
        let screenPoints = points.map { point in
            CGPoint(
                x: centerX + point.x * mmToPixels,
                y: centerY + point.y * mmToPixels
            )
        }
        let centroid = polygonCentroid(of: screenPoints)
        let segmentCount = isClosed ? points.count : max(0, points.count - 1)

        // Draw lines between points
        if points.count >= 2 {
            for i in 0..<segmentCount {
                let start = points[i]
                let end = points[(i + 1) % points.count]
                let startPoint = screenPoints[i]
                let endPoint = screenPoints[(i + 1) % points.count]
                let isWallLocked = lockedCornerIndices.contains(i) || lockedCornerIndices.contains((i + 1) % points.count)

                context.stroke(
                    Path { path in
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    },
                    with: .color(isWallLocked ? lockedColor : lineColor),
                    lineWidth: isWallLocked ? 3.5 : 3
                )

                drawCADDimension(
                    context: context,
                    wallIndex: i,
                    worldStart: start,
                    worldEnd: end,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    centroid: centroid,
                    isLocked: isWallLocked
                )
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
            let isLockedCorner = lockedCornerIndices.contains(index)
            let fillColor: Color = isCloseTarget ? .green : (isLockedCorner ? lockedColor : pointColor)

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

            if isLockedCorner {
                context.draw(
                    Text("L")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white),
                    at: screenPoint
                )
            }

            let cornerLabel = isLockedCorner ? "C\(index + 1) [L]" : "C\(index + 1)"
            context.draw(
                Text(cornerLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isLockedCorner ? lockedColor : .secondary),
                at: CGPoint(x: screenPoint.x + 22, y: screenPoint.y - 14),
                anchor: .leading
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

            if angleConstraintMode != .free {
                let indicatorText = "Angle: \(angleConstraintMode.rawValue)"
                let indicatorOrigin = CGPoint(x: current.x + 14, y: current.y - 26)
                let indicatorRect = CGRect(x: indicatorOrigin.x - 6, y: indicatorOrigin.y - 4, width: 92, height: 22)

                context.fill(
                    Path(roundedRect: indicatorRect, cornerRadius: 6),
                    with: .color(Color.black.opacity(0.75))
                )
                context.draw(
                    Text(indicatorText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white),
                    at: indicatorOrigin,
                    anchor: .topLeading
                )
            }
        }
    }

    private func drawCADDimension(
        context: GraphicsContext,
        wallIndex: Int,
        worldStart: RoomPoint,
        worldEnd: RoomPoint,
        startPoint: CGPoint,
        endPoint: CGPoint,
        centroid: CGPoint,
        isLocked: Bool
    ) {
        let vx = endPoint.x - startPoint.x
        let vy = endPoint.y - startPoint.y
        let screenLength = hypot(vx, vy)
        guard screenLength > 0.1 else { return }

        let ux = vx / screenLength
        let uy = vy / screenLength

        var nx = -uy
        var ny = ux

        let midX = (startPoint.x + endPoint.x) / 2
        let midY = (startPoint.y + endPoint.y) / 2
        let toCentroidX = centroid.x - midX
        let toCentroidY = centroid.y - midY
        if nx * toCentroidX + ny * toCentroidY > 0 {
            nx = -nx
            ny = -ny
        }

        let levelOffset = dimensionOffsetBase + CGFloat(wallIndex % 4) * dimensionOffsetStep
        let extensionStart = CGPoint(x: startPoint.x + nx * extensionLeadIn, y: startPoint.y + ny * extensionLeadIn)
        let extensionEnd = CGPoint(x: endPoint.x + nx * extensionLeadIn, y: endPoint.y + ny * extensionLeadIn)
        let dimensionStart = CGPoint(x: startPoint.x + nx * levelOffset, y: startPoint.y + ny * levelOffset)
        let dimensionEnd = CGPoint(x: endPoint.x + nx * levelOffset, y: endPoint.y + ny * levelOffset)

        context.stroke(
            Path { path in
                path.move(to: extensionStart)
                path.addLine(to: dimensionStart)
            },
            with: .color(extensionLineColor),
            lineWidth: 1
        )
        context.stroke(
            Path { path in
                path.move(to: extensionEnd)
                path.addLine(to: dimensionEnd)
            },
            with: .color(extensionLineColor),
            lineWidth: 1
        )

        context.stroke(
            Path { path in
                path.move(to: dimensionStart)
                path.addLine(to: dimensionEnd)
            },
            with: .color(isLocked ? lockedColor : dimensionLineColor),
            lineWidth: 1.5
        )

        let tickLength: CGFloat = 4
        context.stroke(
            Path { path in
                path.move(to: CGPoint(x: dimensionStart.x - nx * tickLength, y: dimensionStart.y - ny * tickLength))
                path.addLine(to: CGPoint(x: dimensionStart.x + nx * tickLength, y: dimensionStart.y + ny * tickLength))
                path.move(to: CGPoint(x: dimensionEnd.x - nx * tickLength, y: dimensionEnd.y - ny * tickLength))
                path.addLine(to: CGPoint(x: dimensionEnd.x + nx * tickLength, y: dimensionEnd.y + ny * tickLength))
            },
            with: .color(isLocked ? lockedColor : dimensionLineColor),
            lineWidth: 1
        )

        let distance = hypot(worldEnd.x - worldStart.x, worldEnd.y - worldStart.y)
        let label = isLocked ? "W\(wallIndex + 1) [L] \(Int(distance.rounded())) mm" : "W\(wallIndex + 1) \(Int(distance.rounded())) mm"
        let labelPoint = CGPoint(
            x: (dimensionStart.x + dimensionEnd.x) / 2 + nx * 11,
            y: (dimensionStart.y + dimensionEnd.y) / 2 + ny * 11
        )
        context.draw(
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isLocked ? lockedColor : .black),
            at: labelPoint
        )
    }

    private func polygonCentroid(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
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

        // When the shape is still open and closeable, check the first-point close target FIRST.
        // This prevents a wall-segment hit-test near the first point from blocking polygon closure.
        if !isClosed && points.count >= 3 {
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

        // Check if tapping near an existing wall segment — works even when polygon is closed
        if points.count >= 2 {
            let tapPoint = CGPoint(x: location.x, y: location.y)
            let segCount = isClosed ? points.count : points.count - 1
            for i in 0..<segCount {
                let a = points[i]
                let b = points[(i + 1) % points.count]
                let aPt = CGPoint(x: centerX + a.x * mmToPixels, y: centerY + a.y * mmToPixels)
                let bPt = CGPoint(x: centerX + b.x * mmToPixels, y: centerY + b.y * mmToPixels)
                let dist = distancePointToSegment(p: tapPoint, a: aPt, b: bPt)
                if dist < 20 {
                    selectedSegmentIndex = i
                    editingDimension = String(Int(hypot(b.x - a.x, b.y - a.y).rounded()))
                    showDimensionInput = true
                    return
                }
            }
        }

        if isClosed { return }

        // Add point
        var newPoint = RoomPoint(x: snappedX, y: snappedY)

        if let anchor = points.last {
            newPoint = applyAngleConstraint(from: anchor, to: newPoint)
        }

        // Check if point is too close to existing points
        let tooClose = points.contains { point in
            let dx = point.x - newPoint.x
            let dy = point.y - newPoint.y
            return sqrt(dx * dx + dy * dy) < gridSize / 4
        }

        if !tooClose {
            points.append(newPoint)
            currentPoint = location
            clearCurrentPointIndicator(after: 0.65)
        }
    }

    private func handleCanvasDragChanged(value: DragGesture.Value, in size: CGSize) {
        if showDimensionInput { return }

        if draggedPointIndex == nil, let hitIndex = findPointNearScreenLocation(value.startLocation, in: size) {
            draggedPointIndex = hitIndex
        }

        if let movingIndex = draggedPointIndex, points.indices.contains(movingIndex) {
            let rawPoint = pointFromScreenLocation(value.location, in: size)
            var adjustedPoint = rawPoint

            if let anchor = anchorPoint(for: movingIndex) {
                adjustedPoint = applyAngleConstraint(from: anchor, to: rawPoint)
            }

            points[movingIndex] = adjustedPoint
            currentPoint = value.location
        } else {
            currentPoint = nil
            offset = CGSize(
                width: lastOffset.width + value.translation.width,
                height: lastOffset.height + value.translation.height
            )
        }
    }

    private func handleCanvasDragEnded() {
        draggedPointIndex = nil
        currentPoint = nil
        lastOffset = offset
    }

    private func findPointNearScreenLocation(_ location: CGPoint, in size: CGSize) -> Int? {
        guard !points.isEmpty else { return nil }
        let centerX = size.width / 2 + offset.width
        let centerY = size.height / 2 + offset.height
        let mmToPixels: Double = 0.1 * scale
        let hitRadius: CGFloat = 18

        var nearestIndex: Int?
        var nearestDistance = CGFloat.infinity

        for (index, point) in points.enumerated() {
            let screenPoint = CGPoint(
                x: centerX + point.x * mmToPixels,
                y: centerY + point.y * mmToPixels
            )
            let distance = hypot(location.x - screenPoint.x, location.y - screenPoint.y)
            if distance < hitRadius && distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        return nearestIndex
    }

    private func pointFromScreenLocation(_ location: CGPoint, in size: CGSize) -> RoomPoint {
        let centerX = size.width / 2 + offset.width
        let centerY = size.height / 2 + offset.height
        let mmToPixels: Double = 0.1 * scale
        let x = (location.x - centerX) / mmToPixels
        let y = (location.y - centerY) / mmToPixels
        return RoomPoint(x: x, y: y)
    }

    private func anchorPoint(for movingIndex: Int) -> RoomPoint? {
        if movingIndex > 0 {
            return points[movingIndex - 1]
        }
        if isClosed && points.count > 1 {
            return points[points.count - 1]
        }
        return nil
    }

    private func applyAngleConstraint(from anchor: RoomPoint, to candidate: RoomPoint) -> RoomPoint {
        guard let angleDegrees = angleConstraintMode.angleDegrees else {
            return candidate
        }

        let theta = angleDegrees * .pi / 180.0
        let dirX = cos(theta)
        let dirY = sin(theta)

        let vx = candidate.x - anchor.x
        let vy = candidate.y - anchor.y
        let projection = vx * dirX + vy * dirY

        return RoomPoint(
            x: anchor.x + projection * dirX,
            y: anchor.y + projection * dirY
        )
    }

    private func undoLastPoint() {
        if !points.isEmpty {
            points.removeLast()
            isClosed = false
        }
    }

    private func clearAll() {
        points.removeAll()
        lockedCornerIndices.removeAll()
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
        guard points.count >= 2,
              let idx = selectedSegmentIndex,
              points.indices.contains(idx),
              let newLen = Double(editingDimension),
              newLen > 0 else {
            showDimensionInput = false
            return
        }

        let nextIndex = (idx + 1) % points.count
        guard points.indices.contains(nextIndex) else {
            showDimensionInput = false
            return
        }

        let a = points[idx]
        let b = points[nextIndex]

        let dx = b.x - a.x
        let dy = b.y - a.y
        let currentLen = sqrt(dx*dx + dy*dy)
        guard currentLen > 0 else {
            showDimensionInput = false
            return
        }

        let lengthScale = newLen / currentLen
        let newB = RoomPoint(x: a.x + dx * lengthScale, y: a.y + dy * lengthScale)
        let deltaX = newB.x - b.x
        let deltaY = newB.y - b.y

        switch dimensionEditMode {
        case .moveSingleCorner:
            if lockedCornerIndices.contains(nextIndex) {
                showConstraintError("Corner C\(nextIndex + 1) is locked.")
                return
            }
            points[nextIndex] = newB

        case .preserveShape:
            var updatedPoints = points
            var indicesToMove: [Int] = [nextIndex]

            if isClosed {
                if nextIndex < points.count - 1 {
                    indicesToMove.append(contentsOf: (nextIndex + 1)..<points.count)
                }
            } else if nextIndex < points.count - 1 {
                indicesToMove.append(contentsOf: (nextIndex + 1)..<points.count)
            }

            if let lockedIndex = indicesToMove.first(where: { lockedCornerIndices.contains($0) }) {
                showConstraintError("Corner C\(lockedIndex + 1) is locked. Unlock it or use Move One Corner.")
                return
            }

            for moveIndex in indicesToMove {
                let point = updatedPoints[moveIndex]
                updatedPoints[moveIndex] = RoomPoint(x: point.x + deltaX, y: point.y + deltaY)
            }

            points = updatedPoints
        }

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

    private func toggleCornerLock(_ index: Int) {
        if lockedCornerIndices.contains(index) {
            lockedCornerIndices.remove(index)
        } else {
            lockedCornerIndices.insert(index)
        }
    }

    private func showConstraintError(_ message: String) {
        dimensionEditErrorMessage = message
        showDimensionInput = false
        showDimensionEditError = true
    }

    private func clearCurrentPointIndicator(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.currentPoint = nil
        }
    }
}

#Preview("Room Settings · Rectangular") {
    PreviewHost(
        title: "Room Settings",
        appState: PreviewFactory.appState(materialType: .laminate, shape: .rectangular)
    ) {
        RoomSettingsView()
    }
}

#Preview("Room Settings · Polygon") {
    PreviewHost(
        title: "Room Settings",
        appState: PreviewFactory.appState(materialType: .laminate, shape: .polygon)
    ) {
        RoomSettingsView()
    }
}

#Preview("Room Designer · Polygon CAD") {
    PreviewHost(
        title: "Room Designer",
        appState: PreviewFactory.appState(materialType: .laminate, shape: .polygon)
    ) {
        RoomDesignerView(initialPoints: PreviewFactory.samplePolygonPoints)
    }
}
