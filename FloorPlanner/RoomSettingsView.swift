import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
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
struct RoomCaptureContainer: UIViewRepresentable {
    @Binding var roomSettings: RoomSettings
    @Environment(\.dismiss) var dismiss

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView()
        view.captureSession.delegate = context.coordinator
        view.delegate = context.coordinator

        // Start session
        let config = RoomCaptureSession.Configuration()
        view.captureSession.run(configuration: config)

        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        var parent: RoomCaptureContainer

        init(_ parent: RoomCaptureContainer) {
            self.parent = parent
        }

        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            return true
        }

        func captureView(_ view: RoomCaptureView, didPresent processedResult: CapturedRoom, error: Error?) {
            if let error = error {
                print("RoomPlan error: \(error)")
                return
            }

            // Extract geometry
            // We'll calculate the bounding box of all walls
            var minX: Float = .infinity
            var minZ: Float = .infinity
            var maxX: Float = -.infinity
            var maxZ: Float = -.infinity

            var hasWalls = false

            for wall in processedResult.walls {
                hasWalls = true

                // Wall dimensions: x=length, y=height, z=width(thickness)
                let dims = wall.dimensions
                let halfLen = dims.x / 2

                // Local corners (along the wall length)
                let c1 = simd_float4(-halfLen, 0, 0, 1)
                let c2 = simd_float4(halfLen, 0, 0, 1)

                // Transform to world space
                let p1 = wall.transform * c1
                let p2 = wall.transform * c2

                minX = min(minX, p1.x, p2.x)
                minZ = min(minZ, p1.z, p2.z)
                maxX = max(maxX, p1.x, p2.x)
                maxZ = max(maxZ, p1.z, p2.z)
            }

            if hasWalls {
                // Convert to mm (meters * 1000)
                let lengthMm = Double(maxX - minX) * 1000
                let widthMm = Double(maxZ - minZ) * 1000

                DispatchQueue.main.async {
                    // Update room settings to rectangular approximation
                    // This is "minimum" requirement met
                    self.parent.roomSettings.lengthMm = lengthMm
                    self.parent.roomSettings.widthMm = widthMm
                    self.parent.roomSettings.shape = .rectangular
                    self.parent.roomSettings.polygonPoints = [] // clear polygon points

                    self.parent.dismiss()
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.dismiss()
                }
            }
        }
    }
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

    private let gridColor = Color.gray.opacity(0.3)
    private let pointColor = Color.blue
    private let lineColor = Color.blue

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
                        if points.count >= 3 {
                            showConfirmation = true
                        }
                    }
                    .disabled(points.count < 3)
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
                Button(action: closePolygon) {
                    Label("Close Shape", systemImage: "checkmark.circle")
                }
                .foregroundColor(.green)
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
                Text("Tap 'Close Shape' when done, or continue adding points")
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
                        .keyboardType(.numberPad)
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
                if i < points.count - 1 {
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
        for point in points {
            let screenPoint = CGPoint(
                x: centerX + point.x * mmToPixels,
                y: centerY + point.y * mmToPixels
            )

            context.fill(
                Path(ellipseIn: CGRect(
                    x: screenPoint.x - 6,
                    y: screenPoint.y - 6,
                    width: 12,
                    height: 12
                )),
                with: .color(pointColor)
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
        }
    }

    private func clearAll() {
        points.removeAll()
        scale = 1.0
        offset = .zero
        lastOffset = .zero
    }

    private func closePolygon() {
        if points.count >= 3 {
            showConfirmation = true
        }
    }

    private func applyDimension() {
        // Future enhancement: adjust point positions based on entered dimension
        showDimensionInput = false
    }

    private func applyDesign() {
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
}