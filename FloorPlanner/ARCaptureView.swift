//
//  ARCaptureView.swift
//  FloorPlanner
//
//  AR Room Scanning using RoomPlan
//

import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
#endif

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
