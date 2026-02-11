# Floor Planner Roadmap

## Version 2.0: Enhanced Features & Platform Expansion

### Core Functionality
- **Multi-Surface Support**: Currently, the data model supports multiple layers, but the UI is focused on the floor. V2 should expand to Walls and Ceilings, allowing users to define a room as a collection of surfaces.
- **Advanced Geometry**: Support for curved walls, L-shaped rooms (without polygon tool), and obstacles (pillars, islands).
- **Undo/Redo System**: Implement `UndoManager` integration for robust history tracking.
- **Cloud Sync**: Optional iCloud integration using `NSPersistentCloudKitContainer` or similar for cross-device sync.

### Material System
- **Layer Management UI**: A dedicated view to manage the stack of layers (e.g., Subfloor -> Underlay -> Laminate).
- **Custom Materials**: Allow users to define their own materials with custom dimensions and costs.
- **Visual Texture Mapping**: Use actual textures in the PreviewView instead of solid colors.

### Platform Expansion
- **iPadOS**: Enhance the iPad experience with Pencil support for drawing room shapes.
- **macOS**: Add keyboard shortcuts for common actions and menu bar integration.
- **Apple Watch**:
    - **Companion App**: A simple watch app to view the "Shopping List" (Purchase Suggestions) while at the store.
    - **Quick Measurement**: Input measurements directly from the watch while measuring a room.
- **visionOS**: AR experience to visualize the floor layout in the actual room using ARKit/RealityKit.

### Developer Experience
- **Unit Testing**: Expand test coverage for the new `CalculatedEngine`.
- **UI Testing**: Add XCUITests for the main user flows.
- **CI/CD**: Set up a workflow for automated building and testing (e.g., Xcode Cloud).

## Future Considerations (V3+)
- **3D Rendering**: Full 3D walkthrough of the room.
- **Project Export**: Export to PDF, DXF, or USDZ formats.
- **Cost Estimation**: Integration with local supplier APIs for real-time pricing.
