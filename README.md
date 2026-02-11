# Floor Planner

A universal SwiftUI app for planning and calculating floor installations. Now supports a wide range of materials including Laminate, Carpet Tiles, Concrete, Paint, and more.

## Features

### Material Types

**Discrete Materials**
- **Laminate / Vinyl / Engineered Wood**: Row-by-row deterministic layout with stagger rules.
- **Carpet / Ceramic Tiles**: Grid-based placement with pattern options (Brick, Monolithic, Quarter-Turn).
- **Plasterboard**: Sheet-based layout (handled as discrete or calculated depending on configuration).

**Continuous Materials**
- **Concrete**: Volume calculation based on room area and layer depth/thickness.
- **Paint**: Coverage calculation based on area (m²/L).
- **Liquid/Applied**: Generic calculator for any applied material.

### Core Functionality

1. **Intelligent Layout**
   - Generates realistic installation plans for discrete materials.
   - Calculates exact quantities and volumes for continuous materials.
   - Handles insufficient stock by marking "NEEDED" pieces.
   - Works with both rectangular and custom polygon rooms.

2. **Layer-Based Model**
   - Projects now support multiple layers (e.g., Subfloor -> Underlay -> Finish).
   - *Note: UI currently exposes the primary layer, with full multi-layer management coming in V2.*

3. **Comprehensive Reports**
   - Area summary (room, usable, installed, needed, waste).
   - Purchase suggestions (Packs/Boxes for discrete, Volume/Units for continuous).
   - Cut lists (material-dependent).

4. **Visual Preview**
   - 2D plan view with zoom and pan.
   - Color-coded pieces for discrete layouts.
   - Visual coverage fill for continuous materials.
   - Interactive legend.

### Platform Support

- **iPhone**: Navigation stack interface optimized for mobile.
- **iPad**: Split view with inputs sidebar and preview/reports.
- **Mac**: Full Mac Catalyst support with native controls.

## Project Structure

```
FloorPlanner/
├── Materials.swift              # Material, Layer, Surface definitions
├── Constants.swift              # Shared constants
├── Models.swift                 # Core data models (Project, RoomSettings)
├── LayoutEngine.swift           # Layout engine protocol & utilities
├── LaminateEngine.swift         # Discrete plank layout
├── TileEngine.swift             # Discrete tile layout
├── CalculatedEngine.swift       # Continuous material calculator
├── PersistenceManager.swift     # Save/load and export functionality
├── FloorPlannerApp.swift        # App entry point and state
├── ContentView.swift            # Main adaptive view
├── MaterialPickerView.swift     # Material selection
├── MaterialSettingsView.swift   # Material-specific options
├── PreviewView.swift            # 2D visual preview
└── ReportsView.swift            # Reports and statistics
```

## Building

### Requirements
- Xcode 15 or later
- iOS 17+ / macOS 14+
- Swift 5.9+

### Xcode Project Setup

The app can be built as a standard Xcode project or using Swift Package Manager for the core library.

#### Swift Package Manager

```bash
swift build
swift test
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for future plans (Version 2.0).

## Code Review

See [CODE_REVIEW.md](CODE_REVIEW.md) for details on architecture, standards, and refactoring.
