# Floor Planner User Guide

A comprehensive guide to using the Floor Planner app for laminate plank and carpet tile installations.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Choosing Material Type](#choosing-material-type)
3. [Configuring Your Room](#configuring-your-room)
4. [Managing Stock](#managing-stock)
5. [Material-Specific Settings](#material-specific-settings)
6. [Generating Layouts](#generating-layouts)
7. [Understanding the Preview](#understanding-the-preview)
8. [Reading Reports](#reading-reports)
9. [Saving and Loading](#saving-and-loading)
10. [Exporting Data](#exporting-data)
11. [Tips and Best Practices](#tips-and-best-practices)

## Getting Started

### First Launch

When you first open Floor Planner, you'll be greeted with a material selection dialog. This is your choice between:

- **Laminate Planks**: For hardwood-style plank flooring
- **Carpet Tiles**: For modular carpet tile installations

Don't worry - you can change this later from the toolbar menu.

### Interface Overview

The app adapts to your device:

**iPhone**: 
- Vertical list of options
- Navigate through sections
- Preview and reports in separate screens

**iPad/Mac**:
- Split view interface
- Inputs on left sidebar
- Preview and reports on right
- Efficient workflow with everything visible

## Choosing Material Type

### When to Use Laminate Planks

Choose laminate when:
- Installing hardwood-style planks
- Need realistic stagger patterns
- Want detailed cut lists per row
- Working with varying plank lengths
- Reusing offcuts is important

### When to Use Carpet Tiles

Choose tiles when:
- Installing modular carpet tiles
- Need grid-based layouts
- Want pattern options (straight/brick)
- Working with square or rectangular tiles
- Edge cutting is primary concern

### Changing Material Type

1. Tap the menu button (•••) in the toolbar
2. Select "Change Material Type"
3. Choose new material type
4. Confirm the warning dialog

⚠️ **Warning**: Changing material type regenerates the layout with new rules. Your current layout will be replaced.

## Configuring Your Room

### Room Dimensions

1. Go to "Room Settings" section
2. Enter measurements in millimeters:
   - **Length**: Longest dimension
   - **Width**: Shorter dimension
   - **Expansion Gap**: Space around perimeter (default 10mm)

**Example**: For a 5m × 4m room:
- Length: 5000mm
- Width: 4000mm
- Expansion Gap: 10mm

### Understanding Areas

The app calculates:
- **Gross Area**: Total room size (Length × Width)
- **Usable Area**: Area after expansion gap removed

Example:
```
Room: 5000mm × 4000mm = 20.00 m²
Gap: 10mm
Usable: 4980mm × 3980mm = 19.82 m²
```

### Waste Factor

Set the waste percentage for shopping calculations:
- **Laminate**: 5-10% (default 7%)
- **Carpet Tiles**: 7-15% (default 10%)

Higher waste factors recommended for:
- Complex room shapes
- Diagonal installations
- First-time installers
- Valuable material

## Managing Stock

### Adding Stock (Optional)

Stock input is optional. You have two options:

#### Option 1: Use Stock List

1. Go to "Stock Items" section
2. Tap "Add Stock Item"
3. Enter dimensions and quantity:
   - Length (mm)
   - Width (mm)
   - Quantity (pieces)
4. Repeat for each stock variation

**Benefits**:
- Uses actual available material
- Calculates remaining inventory
- Identifies shortfall precisely
- Optimizes offcut reuse

**Example Laminate Stock**:
```
2405mm × 300mm × 13 pieces
2159mm × 300mm × 2 pieces
1607mm × 200mm × 6 pieces
1202mm × 300mm × 6 pieces
```

#### Option 2: No Stock (Default Sizing)

Leave stock list empty to:
- Use default unit sizes
- Calculate quantity needed
- Get shopping list directly

**Benefits**:
- Quick planning mode
- Pre-purchase calculations
- Material estimation
- Budget planning

### Editing Stock

- Swipe left on item to delete
- Tap item to edit (not yet implemented)
- View total stock area at bottom

## Material-Specific Settings

### Laminate Plank Settings

#### Default Plank Size
Set the purchase plank dimensions:
- **Length**: Typical plank length (default 1000mm)
- **Width**: Plank width (default 300mm)

Used when:
- No stock is provided
- Stock runs out (NEEDED pieces)

#### Plank Direction
Choose row orientation:
- **Along Length**: Planks run parallel to room length
- **Along Width**: Planks run parallel to room width

**Rule of Thumb**: 
- Run planks along longest wall
- Consider light direction
- Match existing flooring

#### Installation Rules

**Min Stagger** (default 200mm):
- Minimum offset between adjacent row start points
- Prevents alignment of end joints
- Typically 150-300mm
- Check manufacturer recommendations

**Min Offcut Length** (default 150mm):
- Shortest piece to keep for reuse
- Shorter pieces discarded as waste
- Typically 150-200mm
- Affects waste calculations

### Carpet Tile Settings

#### Tile Size
Square tile dimension (default 500mm):
- Common sizes: 500mm, 600mm, 1000mm
- Must match actual tiles
- Used for grid calculations

#### Pattern Options

**Straight Grid**:
- All tiles aligned
- Traditional look
- Easier installation
- Less waste

**Brick/Offset**:
- Every other row offset by 1/2 tile
- Brick-like pattern
- Hides seams better
- May create more edge cuts

#### Orientation Options

**Monolithic**:
- All tiles same direction
- Pile direction aligned
- Uniform appearance
- Shows seams more

**Quarter-Turn**:
- Alternate tiles rotated 90°
- Checkerboard effect
- Hides seams
- More forgiving
- No impact on cuts

#### Advanced Options

**Reuse Edge Offcuts** (toggle):
- OFF: Cut tiles treated as waste (conservative)
- ON: Track cut tiles for potential reuse (advanced)

**Tiles Per Box** (optional):
- Enter number of tiles per carton
- App calculates boxes needed
- Helps with ordering

## Generating Layouts

### Step-by-Step

1. Configure all settings:
   - Room dimensions
   - Stock (if using)
   - Material settings
   - Waste factor

2. Tap **"Generate Layout"** button

3. Wait for processing (usually instant)

4. View results in Preview and Reports tabs

### What Happens During Generation

The app:
1. Validates all inputs
2. Calculates usable area
3. Selects appropriate layout engine
4. Runs placement algorithm
5. Tracks all cuts and offcuts
6. Identifies needed materials
7. Generates reports

### Understanding Results

**Complete Coverage**:
- All pieces are "Installed" (green)
- No "Needed" pieces (red)
- Sufficient stock available

**Partial Coverage**:
- Mix of "Installed" and "Needed" pieces
- Shows exact shortfall
- Purchase suggestions provided

## Understanding the Preview

### Visual Elements

**Room Outline** (gray solid line):
- Full room perimeter
- Shows gross dimensions

**Usable Area** (blue dashed line):
- Area after expansion gap
- Where material goes
- Shows usable dimensions

**Installed Pieces** (green solid):
- Material from stock
- Successfully placed
- Ready to install

**Needed Pieces** (red dashed):
- Virtual pieces
- Required to complete
- Must be purchased

### Preview Controls

**Zoom**: Pinch gesture (iOS) or scroll (Mac)
**Pan**: Drag gesture
**Fit**: Reset to default view

**Legend**: Shows color meanings at bottom left

### Piece Labels

- **S1, S2, ...**: From stock
- **O1, O2, ...**: From offcuts (laminate)
- **T1, T2, ...**: Tiles (carpet)
- **N1, N2, ...**: Needed pieces

## Reading Reports

### Area Summary

Key metrics:
- **Room Area**: Total room size
- **Usable Area**: After expansion gap
- **Installed Coverage**: Material placed from stock
- **Needed Coverage**: Additional material required
- **Waste Area**: Leftover material
- **Surplus**: Extra material (if any)
- **Completion**: Percentage complete

### Purchase Suggestions

Shows what to buy:
- Unit dimensions
- Quantity needed
- Packs/boxes (if configured)

**Example**:
```
1000mm × 300mm: 15 pieces
OR
1000mm × 300mm: 2 packs (8 pieces/pack)
```

### Cut List

#### Laminate
Shows each cut:
- Row number
- Cut type (Start or End)
- Original length
- Cut to length
- Offcut length

**Example**:
```
Row 1: Start Cut
  2405mm → 200mm (offcut: 2205mm)
Row 1: End Cut
  2205mm → 1900mm (offcut: 305mm)
```

#### Tiles
Shows edge cuts:
- Total edge cut count
- Dimensions note

**Example**:
```
Edge Cuts: 24 tiles
Edge tiles (various dimensions)
```

### Remaining Inventory

Lists leftover material:
- Dimensions
- Source (Stock or Offcut)
- Usable for other projects

### Placement Statistics

Summary counts:
- Pieces installed
- Pieces needed
- Total pieces

## Saving and Loading

### Auto-Save

Projects auto-save when you:
- Generate a layout
- Tap "Save Project" in menu

### Saved Location

Projects saved to:
```
Documents/Projects/[project-id].json
```

### Loading Projects

Currently loads last project on launch.

**Future**: Project browser to select from saved projects

### Project Data Includes

- Material type
- Room settings
- Stock items
- Material settings
- Timestamps

## Exporting Data

### Available Exports

**CSV Files**:
1. Placements list (all pieces with coordinates)
2. Cut list (material-specific)
3. Remaining inventory
4. Purchase list

**PNG Image**:
- Preview snapshot (planned feature)

### Export Process

1. View Reports tab
2. Tap "Export All Reports (CSV)"
3. Choose save location
4. Select destination app

### Using Exported Data

**Spreadsheet** (Excel, Numbers):
- Open CSV files
- Sort, filter, analyze
- Create custom reports

**On-Site Reference**:
- Print placement list
- Check cut list while working
- Track material usage

**Documentation**:
- Save for records
- Include in project files
- Share with team

## Tips and Best Practices

### Room Measurement

1. **Measure accurately**: Use laser measure or steel tape
2. **Check corners**: Verify 90° angles
3. **Account for obstacles**: Note fixed objects
4. **Document**: Take photos and notes

### Stock Management

1. **Inventory first**: Count before starting
2. **Group by size**: Sort similar pieces
3. **Label clearly**: Mark dimensions
4. **Check quality**: Remove damaged pieces

### Layout Planning

**Laminate**:
- Start with longest pieces
- Plan for doorways
- Consider light direction
- Leave extra for mistakes

**Tiles**:
- Plan pattern first
- Mark center lines
- Check square
- Order extra box

### Material Ordering

1. **Check calculations**: Review purchase suggestions
2. **Add buffer**: Consider +5-10% extra
3. **Match batches**: Order all at once
4. **Keep receipts**: For returns/exchanges

### Installation

**Before Starting**:
- Acclimate material
- Prepare subfloor
- Gather tools
- Read instructions

**During Install**:
- Follow layout plan
- Check frequently
- Track actual cuts
- Save offcuts

**After Completion**:
- Store leftovers properly
- Label extras
- Update inventory
- Document project

### Troubleshooting

**Layout looks wrong**:
- Check room dimensions
- Verify material settings
- Try different direction
- Regenerate layout

**Stock insufficient**:
- Review purchase suggestions
- Add to stock list
- Regenerate with new stock

**Numbers don't match**:
- Check unit conversions
- Verify area calculations
- Consider waste factor
- Review expansion gap

## Advanced Features

### Multiple Scenarios

Test different options:
1. Save current project
2. Modify settings
3. Generate new layout
4. Compare results
5. Choose best option

### Material Comparison

Compare materials:
1. Generate laminate layout
2. Note material requirements
3. Switch to tile
4. Compare coverage and cost

### Optimization

Minimize waste:
1. Try different directions
2. Adjust start positions
3. Modify stagger distance
4. Use offcuts wisely

## Support

### Common Issues

See BUILDING.md and ARCHITECTURE.md for technical details.

### Feedback

Report issues or suggest features via GitHub Issues.

### Contributing

Contributions welcome! See repository for guidelines.

## Appendix

### Unit Conversions

```
1 meter = 1000 millimeters
1 m² = 1,000,000 mm²

Example:
2000mm × 1500mm = 3,000,000mm² = 3m²
```

### Common Plank Sizes

```
Laminate:
- 1215mm × 195mm (Europe)
- 1200mm × 190mm (Common)
- 1380mm × 190mm (Premium)
- 1845mm × 244mm (Wide plank)
```

### Common Tile Sizes

```
Carpet Tiles:
- 500mm × 500mm (Standard)
- 600mm × 600mm (Large)
- 1000mm × 250mm (Plank style)
- 1000mm × 1000mm (Metro)
```

### Expansion Gap Guidelines

```
Laminate:
- Small rooms (< 20m²): 8-10mm
- Medium rooms (20-40m²): 10-12mm
- Large rooms (> 40m²): 12-15mm
- Fixed objects: 5mm

Tiles:
- Not required (adhered)
- Or 5mm for floating installations
```

### Stagger Guidelines

```
Laminate:
- Minimum: 150-200mm
- Optimal: 300-400mm
- Maximum: 1/2 plank length
- Never align within 3 rows
```

---

*This guide covers version 1.0 of Floor Planner*
