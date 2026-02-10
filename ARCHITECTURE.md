# Floor Planner Architecture

## Overview

The Floor Planner app follows a clean architecture pattern with clear separation between data models, business logic (layout engines), and UI (SwiftUI views).

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  (SwiftUI Views - iPhone/iPad/Mac adaptive interfaces)      │
│                                                              │
│  ContentView → MaterialPickerView                            │
│             → RoomSettingsView                               │
│             → StockTableView                                 │
│             → MaterialSettingsView                           │
│             → PreviewView (Canvas)                           │
│             → ReportsView                                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ @EnvironmentObject
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    State Management                          │
│                      (AppState)                              │
│                                                              │
│  • Current Project                                           │
│  • Layout Result                                             │
│  • Material Selection                                        │
│  • generateLayout()                                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ uses
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic Layer                       │
│                   (Layout Engines)                           │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐                       │
│  │   Laminate   │    │     Tile     │                       │
│  │    Engine    │    │    Engine    │                       │
│  └──────┬───────┘    └──────┬───────┘                       │
│         │                    │                               │
│         └────────┬───────────┘                               │
│                  │ implements                                │
│                  ▼                                           │
│         ┌────────────────┐                                   │
│         │ LayoutEngine   │ (Protocol)                        │
│         │   Protocol     │                                   │
│         └────────────────┘                                   │
│                  │                                           │
│                  │ uses                                      │
│                  ▼                                           │
│         ┌────────────────┐                                   │
│         │    Layout      │                                   │
│         │   Utilities    │                                   │
│         └────────────────┘                                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ operates on
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│                      (Models)                                │
│                                                              │
│  Project ──────┐                                             │
│  │             ├──→ RoomSettings                             │
│  │             ├──→ [StockItem]                              │
│  │             ├──→ LaminateSettings?                        │
│  │             └──→ TileSettings?                            │
│  │                                                           │
│  └──→ LayoutResult ──┐                                       │
│       │              ├──→ [PlacedPiece]                      │
│       │              ├──→ [CutRecord]                        │
│       │              ├──→ [RemainingPiece]                   │
│       │              └──→ [PurchaseSuggestion]               │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ persisted by
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  Persistence Layer                           │
│                (PersistenceManager)                          │
│                                                              │
│  • Save/Load Project JSON                                    │
│  • Export CSV (Placements, Cuts, Inventory, Purchase)       │
│  • Export PNG (Preview)                                      │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. User Input Flow
```
User Input (Views)
    ↓
AppState.currentProject (update)
    ↓
User taps "Generate Layout"
    ↓
AppState.generateLayout()
```

### 2. Layout Generation Flow
```
AppState.generateLayout()
    ↓
Select Engine (Laminate or Tile)
    ↓
Engine.generateLayout(project, useStock)
    ↓
    ├─→ Read room settings
    ├─→ Process stock items
    ├─→ Execute algorithm
    │   ├─→ Place pieces
    │   ├─→ Track cuts
    │   ├─→ Manage offcuts
    │   └─→ Calculate needed pieces
    ↓
Return LayoutResult
    ↓
AppState.layoutResult = result
    ↓
UI updates (Preview + Reports)
```

### 3. Persistence Flow
```
User saves project
    ↓
AppState.saveProject()
    ↓
PersistenceManager.saveProject(project)
    ↓
JSON.encode(project)
    ↓
Write to Documents/Projects/
```

## Key Components

### Models (Models.swift)
- **Project**: Main container for all project data
- **MaterialType**: Enum for Laminate vs Carpet Tile
- **RoomSettings**: Dimensions and gap settings
- **StockItem**: Individual stock piece definition
- **LaminateSettings**: Laminate-specific options
- **TileSettings**: Tile-specific options
- **PlacedPiece**: A piece placed in the layout
- **CutRecord**: Record of a cut made
- **RemainingPiece**: Leftover inventory
- **PurchaseSuggestion**: What to buy to complete
- **LayoutResult**: Complete layout output

### Layout Engines

#### LayoutEngine Protocol
```swift
protocol LayoutEngine {
    func generateLayout(
        project: Project,
        useStock: Bool
    ) -> LayoutResult
}
```

#### LaminateEngine
Algorithm:
1. Determine primary plank width
2. Calculate number of rows
3. For each row:
   - Calculate stagger offset
   - Place planks left to right
   - Try offcuts first
   - Cut and track as needed
   - Use NEEDED pieces when out of stock

#### TileEngine
Algorithm:
1. Calculate grid dimensions
2. For each grid position:
   - Calculate tile size (may be cut at edges)
   - Apply pattern offset (brick)
   - Apply rotation (quarter-turn)
   - Mark as installed or needed

### Views

#### Platform Adaptation
```
iPhone:     NavigationStack (vertical list)
iPad/Mac:   NavigationSplitView (sidebar + detail)
```

#### View Hierarchy
```
ContentView (root)
├─ MaterialPickerView (sheet)
├─ RoomSettingsView
├─ StockTableView
│  └─ AddStockItemView (sheet)
├─ MaterialSettingsView
├─ PreviewView (Canvas)
└─ ReportsView
```

## Material-Specific Behavior

### Laminate Mode
```
Settings Available:
- Plank direction (along length/width)
- Min stagger (default 200mm)
- Min offcut length (default 150mm)
- Default plank size

Layout Rules:
- Row-by-row placement
- Stagger between rows
- Offcut reuse (if > min length)
- Cut tracking per row

Output:
- Detailed cut list with row numbers
- Offcuts tracked separately
- Start/end cuts recorded
```

### Tile Mode
```
Settings Available:
- Tile size (default 500mm)
- Pattern (straight/brick)
- Orientation (monolithic/quarter-turn)
- Reuse edge offcuts (toggle)
- Tiles per box

Layout Rules:
- Grid-based placement
- Optional brick offset (1/2 tile)
- Optional rotation (90° alternating)
- Edge cuts for partial tiles

Output:
- Edge cut count
- Full vs partial tiles
- Rotation info for each tile
```

## Extension Points

### Adding New Material Types
1. Add case to `MaterialType` enum
2. Create settings struct (e.g., `VinylSettings`)
3. Implement `LayoutEngine` protocol
4. Add to `MaterialSettingsView`
5. Update `AppState.changeMaterialType()`

### Adding New Features
- **Undo/Redo**: Implement via AppState history
- **Multiple Rooms**: Array of RoomSettings
- **Custom Shapes**: Extend RoomSettings with polygon
- **Cost Tracking**: Add price fields to StockItem
- **Material Library**: Presets for common materials

## Testing Strategy

### Unit Tests
- Model calculations (areas, dimensions)
- Layout algorithms (both engines)
- Persistence (save/load/export)
- Edge cases (no stock, insufficient stock)

### Integration Tests
- Full layout generation pipeline
- Multi-material switching
- Large dataset handling

### UI Tests
- Navigation flows
- Form inputs
- Export operations

## Performance Considerations

### Optimization Areas
1. **Layout Generation**: O(n) complexity where n = pieces
   - Laminate: Linear per row
   - Tile: Linear grid iteration

2. **Preview Rendering**: Canvas draw calls
   - Minimize redraws
   - Use efficient stroke/fill

3. **Stock Management**: Array operations
   - Pre-sort by size
   - Binary search for best-fit

### Memory Management
- Models are value types (structs)
- Large layouts tracked efficiently
- Codable for serialization

## Security & Privacy

### Permissions Required
- File Access (User Selected): For export functionality

### Data Storage
- Local only (Documents directory)
- No cloud sync (optional future feature)
- No analytics or tracking
- No third-party services

### Best Practices
- Validate all user input
- Sanitize file names for export
- Check bounds on calculations
- Handle division by zero
- Graceful error handling
