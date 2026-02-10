# Parametric Room Designer - UI Mockup

## Room Settings View - Updated Interface

```
┌─────────────────────────────────────┐
│ Room Settings                       │
├─────────────────────────────────────┤
│                                     │
│ ROOM TYPE                           │
│ ┌─────────────────────────────────┐ │
│ │ Rectangular │ Custom Polygon    │ │ ← Segmented Picker (NEW)
│ └─────────────────────────────────┘ │
│                                     │
│ When "Custom Polygon" selected:    │
│ ┌─────────────────────────────────┐ │
│ │ 📐 Design Custom Room        > │ │ ← Button launches designer
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Points Defined           6      │ │ ← Shows point count
│ └─────────────────────────────────┘ │
│                                     │
│ EXPANSION GAP                       │
│ ┌─────────────────────────────────┐ │
│ │ Expansion Gap (mm)       10     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ CALCULATED AREAS                    │
│ ┌─────────────────────────────────┐ │
│ │ Gross Area          16.00 m²    │ │ ← Polygon area
│ │ Usable Area         15.76 m²    │ │
│ │ Bounding Box        6000×4000mm │ │ ← NEW for polygons
│ └─────────────────────────────────┘ │
│                                     │
│ WASTE FACTOR                        │
│ ┌─────────────────────────────────┐ │
│ │ Waste Factor (%)     7.0        │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## Room Designer View - CAD Interface

### Initial State (No Points)
```
┌─────────────────────────────────────┐
│ ✕  Room Designer              Done │ ← Navigation Bar
├─────────────────────────────────────┤
│ [🗑️ Clear]  [✓ Close Shape]  [⟲ Undo] │ ← Toolbar (Close Shape disabled)
├─────────────────────────────────────┤
│                                     │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │ 
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │ ← Grid canvas
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │   (500mm squares)
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│                                     │
├─────────────────────────────────────┤
│ Tap to place the first corner point│ ← Instructions
│ Points: 0  Grid: 500mm  Zoom: 1.0x │ ← Status
└─────────────────────────────────────┘
```

### With Points Placed (Drawing Room)
```
┌─────────────────────────────────────┐
│ ✕  Room Designer              Done │
├─────────────────────────────────────┤
│ [🗑️ Clear]  [✓ Close Shape]  [⟲ Undo] │ ← Close Shape now enabled
├─────────────────────────────────────┤
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ●───────6000mm───────●   ┊   │ ← Points (●) and walls
│   ┊   │   ┊   ┊   ┊   ┊   │   ┊   │
│   ┊   │   ┊   ┊   ┊   ┊   │   ┊   │
│ 4000mm│   ┊   ┊   ┊   ┊2000mm  ┊   │ ← Dimension labels
│   ┊   │   ┊   ┊   ┊   ┊   ●   ┊   │
│   ┊   │   ┊   ┊   ┊   ┊   │   ┊   │
│   ┊   │   ┊   ●───2000mm───┘   ┊   │ ← L-shaped room
│   ┊   │   ┊2000mm  ┊   ┊   ┊   ┊   │
│   ┊   ●───┘   ┊   ┊   ┊   ┊   ┊   │
│   ┊   ┊   ┊   ┊   ┊   ┊   ┊   ┊   │
├─────────────────────────────────────┤
│ Tap 'Close Shape' when done, or    │
│ continue adding points              │
│ Points: 6  Grid: 500mm  Zoom: 1.0x │
└─────────────────────────────────────┘
```

### Zoom and Pan
```
Gestures:
- Pinch out/in: Zoom
- One finger drag: Pan
- Tap: Add point

Zoomed In View (scale 2.0x):
┌─────────────────────────────────────┐
│   ●───────6000mm───────●            │
│   │                    │            │
│   │                    │            │
│   │        [Larger     │            │
│   │         detail     │            │
│   │         view]    4000mm         │
│   │                    │            │
│   │                    │            │
│   │                    ●            │
└─────────────────────────────────────┘
```

## Preview View - Polygon Room Display

### Rectangular Room (Existing)
```
┌─────────────────────────────────────┐
│ Preview                             │
├─────────────────────────────────────┤
│                                     │
│   ┌─────────────────────────────┐   │
│   │ ╭─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ╮ │   │ ← Usable area (dashed)
│   │ ┊ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐┊ │   │
│   │ ┊ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘┊ │   │ ← Placed pieces
│   │ ┊ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐┊ │   │   (green = installed)
│   │ ┊ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘┊ │   │
│   │ ╰─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ╯ │   │
│   └─────────────────────────────┘   │ ← Room outline (solid)
│                                     │
│  [Fit] Zoom: 1.0x  [Export ↗]     │
└─────────────────────────────────────┘
```

### Polygon Room (NEW)
```
┌─────────────────────────────────────┐
│ Preview                             │
├─────────────────────────────────────┤
│                                     │
│   ●───────────────────────●         │ ← Polygon outline
│   │ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ │         │   with vertices (●)
│   │ └─┘ └─┘ └─┘ └─┘ └─┘ │         │
│   │ ┌─┐ ┌─┐ ┌─┐ ┌─┐     ●         │ ← L-shaped room
│   │ └─┘ └─┘ └─┘ └─┘     │         │
│   │ ┌─┐ ┌─┐             │         │ ← Pieces placed
│   │ └─┘ └─┘ ●───────────┘         │   within polygon
│   │ ┌─┐ ┌─┐ │                     │
│   ●─┴─┴─┴─┴─●                     │
│                                     │
│  [Fit] Zoom: 1.0x  [Export ↗]     │
└─────────────────────────────────────┘
```

## Color Legend

```
Room Designer:
- Grid lines: Gray (30% opacity)
- Points: Blue filled circles
- Lines: Blue solid (3px)
- Dimension labels: Blue text

Preview:
- Room outline: Gray solid (2px)
- Usable area: Blue dashed (rectangular only)
- Polygon vertices: Blue dots
- Installed pieces: Green fill (30% opacity), green border
- Needed pieces: Red fill (20% opacity), red dashed border
```

## Example Workflows

### Workflow 1: Creating L-Shaped Room

1. User opens Room Settings
2. Changes picker to "Custom Polygon"
3. Taps "Design Custom Room"
4. Designer opens with empty grid
5. User taps 6 points to create L-shape:
   ```
   Point 1: (0, 0)      - Bottom left
   Point 2: (6000, 0)   - Bottom right  
   Point 3: (6000, 4000)- Top right
   Point 4: (2000, 4000)- Inner corner top
   Point 5: (2000, 2000)- Inner corner bottom
   Point 6: (0, 2000)   - Left middle
   ```
6. Taps "Close Shape"
7. Taps "Done"
8. Confirmation: "Apply Room Design?"
9. Taps "Apply"
10. Back to Room Settings - shows 6 points, 16.00 m²

### Workflow 2: Generating Layout with Polygon

1. User has L-shaped room defined
2. Configures material and stock
3. Taps "Generate Layout"
4. Layout engine:
   - Uses bounding box (6000×4000) for initial placement
   - Validates each piece with contains(x, y)
   - Places pieces in L-shaped area only
5. Preview shows:
   - L-shaped room outline
   - Pieces within the L
   - Empty space where cutout is
   - Vertex markers

### Workflow 3: Editing Existing Polygon

1. User has polygon room
2. Opens Room Settings
3. Taps "Design Custom Room"
4. Designer opens with existing points
5. Taps "Undo" to remove last 2 points
6. Places new points
7. Taps "Close Shape"
8. Taps "Done"
9. Confirms apply
10. Room updated

## Technical Notes

### Coordinate System

```
Origin (0,0) is at top-left of canvas
X increases to the right
Y increases downward

Example room:
(0,0)●──────────────●(6000,0)
     │              │
     │              │
     │              │
     │              │
(0,4000)●──────────●(6000,4000)
```

### Grid Snapping

```
Grid size: 500mm
Snap threshold: 125mm (1/4 grid)

Point placement:
User taps at (750, 1200)
↓
Snaps to (500, 1000) - nearest grid intersection
```

### Area Calculation Display

```
Room Type: Custom Polygon
Points: 6

Calculations shown:
- Gross Area: 16.00 m² (shoelace formula)
- Usable Area: 15.76 m² (approx, after gap)
- Bounding Box: 6000×4000mm (for layout engine)
- Perimeter: 18000mm (for gap calculation)
```

## Accessibility

- All buttons have labels
- Status text is readable
- Dimension labels are clear
- High contrast colors
- Supports Dynamic Type
- VoiceOver compatible

## Performance

- Efficient Canvas rendering
- Smooth zoom/pan gestures
- Real-time dimension updates
- Handles up to 50 points
- No lag with complex shapes

---

**Implementation Status:**
- ✅ Models and data structures
- ✅ Room Designer View (SwiftUI + Canvas)
- ✅ Room Settings integration
- ✅ Preview rendering
- ⏳ Layout engine integration (pending)
- ⏳ Manual testing (requires Xcode build)
