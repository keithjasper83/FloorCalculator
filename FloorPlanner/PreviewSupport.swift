import SwiftUI

@MainActor
enum PreviewFactory {
    static var samplePolygonPoints: [RoomPoint] {
        [
            RoomPoint(x: 0, y: 0),
            RoomPoint(x: 5200, y: 0),
            RoomPoint(x: 5200, y: 2600),
            RoomPoint(x: 3200, y: 2600),
            RoomPoint(x: 3200, y: 4100),
            RoomPoint(x: 0, y: 4100)
        ]
    }

    static func appState(
        materialType: MaterialType = .laminate,
        shape: RoomShape = .rectangular,
        includeLayout: Bool = false
    ) -> AppState {
        let state = AppState()
        state.isFirstLaunch = false

        switch materialType {
        case .laminate, .vinylPlank, .engineeredWood:
            state.currentProject = Project.sampleLaminateProject()
            state.currentProject.materialType = materialType
        case .carpetTile, .ceramicTile:
            state.currentProject = Project.sampleTileProject()
            state.currentProject.materialType = materialType
        case .concrete, .paint, .plasterboard:
            state.currentProject = Project(
                name: "Sample \(materialType.rawValue)",
                materialType: materialType,
                roomSettings: RoomSettings(lengthMm: 6000, widthMm: 3500, expansionGapMm: 10),
                stockItems: [],
                wasteFactor: 5.0
            )
        }

        if shape == .polygon {
            state.currentProject.roomSettings.shape = .polygon
            state.currentProject.roomSettings.polygonPoints = samplePolygonPoints
            state.currentProject.roomSettings.lengthMm = 5200
            state.currentProject.roomSettings.widthMm = 4100
        }

        if includeLayout {
            state.generateLayout()
        } else {
            state.layoutResult = nil
        }

        return state
    }
}

struct PreviewHost<Content: View>: View {
    let title: String?
    let appState: AppState
    private let content: () -> Content

    init(
        title: String? = nil,
        appState: AppState,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.appState = appState
        self.content = content
    }

    var body: some View {
        NavigationStack {
            content()
                .applyOptionalNavigationTitle(title)
        }
        .environmentObject(appState)
    }
}

private extension View {
    @ViewBuilder
    func applyOptionalNavigationTitle(_ title: String?) -> some View {
        if let title {
            navigationTitle(title)
        } else {
            self
        }
    }
}
