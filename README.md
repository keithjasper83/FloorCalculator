# Floor Planner

A universal SwiftUI app for planning and calculating floor installations with support for laminate planks and carpet tiles.

## Features

### Room Configuration

**Rectangular Mode (Traditional)**
- Simple length and width input
- Perfect for standard rectangular rooms
- Quick and easy setup

**Parametric Designer (NEW!)**
- CAD-style line drawing tool
- Create complex room shapes (L-shaped, U-shaped, irregular)
- Click to place points and draw walls
- Automatic dimension calculation
- Snap-to-grid for precise measurements
- Visual grid canvas with zoom and pan
- See [PARAMETRIC_ROOM_GUIDE.md](PARAMETRIC_ROOM_GUIDE.md) for details

### Material Types

**Laminate Planks**
- Row-by-row deterministic layout with realistic installation rules
- Configurable stagger distance between rows
- Offcut reuse and waste tracking
- Cut list generation for each row

**Carpet Tiles**
- Grid-based placement with pattern options
- Monolithic or quarter-turn orientation
- Straight grid or brick/offset patterns
- Edge cut tracking

### Core Functionality

1. **Stock Management (Optional)**
   - Define stock items with dimensions and quantities
   - Or use default unit sizes without stock
   - Automatic calculation of required quantities

2. **Intelligent Layout**
   - Generates realistic installation plans
   - Handles insufficient stock by marking "NEEDED" pieces
   - Continues planning even when stock runs out
   - Shows exactly what additional materials are required
   - Works with both rectangular and custom polygon rooms

3. **Comprehensive Reports**
   - Area summary (room, usable, installed, needed, waste)
   - Over/short analysis
   - Purchase suggestions with pack/box rounding
   - Cut lists (material-dependent)
   - Remaining inventory tracking

4. **Visual Preview**
   - 2D plan view with zoom and pan
   - Color-coded pieces (installed vs needed)
   - Room outline and usable area boundaries
   - Support for polygon room shapes
   - Interactive legend

5. **Export Capabilities**
   - Save/load projects as JSON
   - Export layout as PNG image (planned)
   - Export data as CSV files:
     - Placements list
     - Cut list
     - Remaining inventory
     - Purchase list

### Platform Support

- **iPhone**: Navigation stack interface optimized for mobile
- **iPad**: Split view with inputs sidebar and preview/reports
- **Mac**: Full Mac Catalyst support with native controls

## Project Structure

```
FloorPlanner/
├── Models.swift                 # Core data models
├── LayoutEngine.swift          # Layout engine protocol
├── LaminateEngine.swift        # Laminate plank layout algorithm
├── TileEngine.swift            # Carpet tile layout algorithm
├── PersistenceManager.swift    # Save/load and export functionality
├── FloorPlannerApp.swift       # App entry point and state
├── ContentView.swift           # Main adaptive view
├── MaterialPickerView.swift    # Material type selection
├── RoomSettingsView.swift      # Room configuration
├── StockTableView.swift        # Stock management
├── MaterialSettingsView.swift  # Material-specific options
├── PreviewView.swift           # 2D visual preview
├── ReportsView.swift           # Reports and statistics
├── Info.plist                  # App configuration
└── FloorPlanner.entitlements   # File access permissions
```

## Configuration

### Room Settings
- Length (mm)
- Width (mm)
- Expansion gap (mm) - default 10mm
- Waste factor (%) - default 7-10%

### Laminate Settings
- Default plank size (length × width)
- Plank direction (along length/width)
- Minimum stagger distance (default 200mm)
- Minimum offcut length (default 150mm)

### Tile Settings
- Tile size (default 500×500mm)
- Pattern (straight grid or brick/offset)
- Orientation (monolithic or quarter-turn)
- Reuse edge offcuts option
- Tiles per box (for pack calculations)

## Sample Data

The app comes preloaded with sample laminate stock:
- 13× planks: 2405×300mm
- 2× planks: 2159×300mm
- 6× planks: 1607×200mm
- 6× planks: 1202×300mm

## Building

### Requirements
- Xcode 15 or later
- iOS 16+ / macOS 13+
- Swift 5.9+

### Xcode Project Setup

The app can be built as a standard Xcode project or using Swift Package Manager for the core library.

#### Creating an Xcode Project

1. Open Xcode
2. Create a new "Multiplatform App" project
3. Name it "FloorPlanner"
4. Copy all Swift files from the `FloorPlanner/` directory into the project
5. Add `Info.plist` and `FloorPlanner.entitlements` to the project
6. Enable Mac Catalyst in project settings
7. Build and run

#### Swift Package Manager

```bash
swift build
swift test
```

### Required Entitlements

The app requires file access entitlements for export functionality:
- `com.apple.security.files.user-selected.read-write`

## Usage

1. **Select Material Type**
   - On first launch, choose between Laminate Planks or Carpet Tiles
   - Change anytime from the toolbar menu

2. **Configure Room**
   - Set room dimensions
   - Adjust expansion gap if needed
   - Set waste factor percentage

3. **Add Stock (Optional)**
   - Add stock items with dimensions and quantities
   - Or leave empty to use default unit sizes

4. **Configure Material Options**
   - Laminate: Set plank direction, stagger rules
   - Tiles: Choose pattern and orientation

5. **Generate Layout**
   - Tap "Generate Layout" button
   - View preview and reports

6. **Review Results**
   - Check area summary and completion percentage
   - Review purchase suggestions
   - Examine cut lists and remaining inventory

7. **Export**
   - Save project for later
   - Export preview as PNG
   - Export reports as CSV

## Algorithm Details

### Laminate Layout Algorithm

1. Determine primary plank width from stock (most abundant)
2. Calculate number of rows based on room width and plank width
3. For each row:
   - Calculate stagger offset (minimum stagger from previous row)
   - Place planks left to right
   - Try to reuse offcuts first (if long enough)
   - Cut planks as needed, track offcuts
   - Use "NEEDED" virtual pieces when stock runs out
4. Discard offcuts shorter than minimum length
5. Generate cut list with all cuts made

### Tile Layout Algorithm

1. Calculate grid dimensions (tiles along length/width)
2. For each grid position:
   - Calculate actual tile size (may be cut at edges)
   - Apply pattern offset if using brick pattern
   - Apply rotation if using quarter-turn orientation
   - Mark as installed (from stock) or needed
3. Track edge cuts separately
4. Calculate waste from partial tiles at edges

## Testing

Run unit tests:
```bash
swift test
```

Tests cover:
- Model calculations
- Layout engine algorithms
- Area calculations
- Persistence (save/load/export)
- Data validation

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

## New Features (Spectacular V1)

### iCloud Sync
Projects are now automatically synced across all your devices using iCloud (Core Data + CloudKit).
- **Requirements**: Signed in to iCloud on all devices. iCloud Drive enabled.
- **Setup**:
  1. Add "iCloud" capability in Xcode.
  2. Check "CloudKit" and use container `iCloud.com.keithjasper83.FloorPlanner`.
  3. Ensure "Background Modes" -> "Remote notifications" is enabled.

### Diagonal Installation
Support for diagonal layouts for both laminate and carpet tiles.
- **Usage**: In Room Settings, select "Diagonal" pattern and adjust the angle (0-60°).
- **Algorithm**: The room is rotated internally, laid out, and then pieces are transformed back.

### AR Room Capture (iOS/iPadOS)
Scan your room using LiDAR-enabled devices.
- **Requirements**: iPhone 12 Pro or later, or iPad Pro (2020 or later) with LiDAR scanner. iOS 16+.
- **Usage**: Tap "Scan Room with AR" in Room Settings.
- **Fallback**: Manual entry is available for unsupported devices.

### Known Limitations
- Diagonal cut precision is approximate for complex polygons near boundaries.
- AR Scan produces a rectangular approximation of the scanned room in this version.