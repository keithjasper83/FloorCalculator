# Parametric Room Designer User Guide

## Overview

The Parametric Room Designer allows you to create complex, non-rectangular room shapes using a CAD-style line drawing tool. This is perfect for L-shaped rooms, rooms with alcoves, or any irregular floor plan.

## Accessing the Designer

1. Open **Room Settings**
2. At the top, change the **Shape** picker from "Rectangular" to "Custom Polygon"
3. Tap **"Design Custom Room"** button
4. The Room Designer will open in a full-screen sheet

## Using the Designer

### Drawing Your Room

1. **First Point**: Tap anywhere on the grid to place the first corner of your room
2. **Second Point**: Tap to place the second corner - a line will appear connecting them
3. **Continue**: Keep tapping to add more corners and walls
4. **Close Shape**: Once you have at least 3 points, tap "Close Shape" to complete your room

### Grid and Scaling

- The grid background shows 500mm (50cm) squares by default
- Points automatically **snap to grid** intersections for precise measurements
- **Pinch to zoom** in/out for better control
- **Drag to pan** around the canvas

### Controls

**Top Toolbar:**
- 🗑️ **Clear**: Remove all points and start over
- ✓ **Close Shape**: Complete your room design (appears when you have 3+ points)
- ⟲ **Undo**: Remove the last point placed

**Bottom Status Bar:**
- Shows number of points placed
- Shows current grid size (500mm)
- Shows zoom level

### Dimension Labels

- Each wall segment shows its length in millimeters
- Labels appear at the midpoint of each line
- Measurements are calculated automatically

## Tips for Best Results

### Planning Your Shape

1. **Start at a corner**: Begin drawing from one corner of your room
2. **Go clockwise or counter-clockwise**: Pick a direction and stick with it
3. **Close the shape**: Make sure your final point connects back to the first point

### Common Room Shapes

**L-Shaped Room:**
1. Start at outer corner
2. Draw along one wall
3. Draw the perpendicular wall
4. Create the "notch" with 2 corners
5. Complete the L by returning to start

**U-Shaped Room:**
1. Start at one outer corner
2. Draw the U shape with 8 points total
3. The interior cutout will be automatic

**Room with Alcove:**
1. Draw the main rectangular room
2. Add the alcove points where needed
3. Continue around back to start

### Grid Alignment

- Grid size is 500mm (half a meter)
- Points snap to grid intersections
- For custom dimensions, you can place points between grid lines (snap can be disabled in future updates)

### Zoom and Pan

- **Zoom In**: Pinch outward to see details
- **Zoom Out**: Pinch inward to see the full room
- **Pan**: Drag with one finger to move around
- **Reset View**: Use the "Fit" button (future feature)

## Applying Your Design

1. Once satisfied with your room shape, tap **"Done"** in the top right
2. A confirmation dialog will appear
3. Tap **"Apply"** to use this shape for your floor plan
4. The designer will close and your custom room will be active

## Technical Details

### Area Calculations

- **Gross Area**: Calculated using the shoelace formula for irregular polygons
- **Bounding Box**: Shows the rectangular area that contains your entire room
- **Usable Area**: Gross area minus expansion gap perimeter

### Expansion Gap

- The expansion gap (default 10mm) applies around the entire perimeter
- For complex shapes, this is calculated as: Gross Area - (Perimeter × Gap Width)

### Layout Generation

When you generate a layout with a custom polygon room:
- The layout engine uses the **bounding box** to determine piece placement
- Pieces are then validated to ensure they fit within the actual polygon shape
- Pieces outside the polygon are marked as "needed" or excluded

## Limitations

### Current Version

- Grid size is fixed at 500mm (future: adjustable)
- Manual dimension entry is planned for future versions
- Points must be placed manually (no import from CAD files yet)
- Expansion gap calculation is approximate for complex shapes

### Recommended

- **Minimum Points**: 3 (triangle)
- **Maximum Points**: 50 (for performance)
- **Minimum Wall Length**: 500mm
- **Grid Snap**: Keep snapping enabled for accurate measurements

## Editing an Existing Design

To modify a custom room shape:

1. Go to **Room Settings**
2. Ensure "Custom Polygon" is selected
3. Tap **"Design Custom Room"**
4. The designer opens with your existing points
5. Use **"Clear"** to start over, or **"Undo"** to remove points
6. Make your changes and tap **"Done"**

## Returning to Rectangular Mode

To go back to simple rectangular rooms:

1. Go to **Room Settings**
2. Change the **Shape** picker back to "Rectangular"
3. The length/width fields will reappear
4. Your custom polygon is saved but not active

You can switch back to "Custom Polygon" anytime to reuse your design.

## Troubleshooting

### "Points are too close together"

- Points must be at least 125mm (1/4 grid) apart
- Solution: Zoom in and place points more carefully

### "Cannot close shape"

- You need at least 3 points to create a valid shape
- Solution: Add more points before tapping "Close Shape"

### "Room appears too small/large"

- The preview scale is automatic based on your room size
- Solution: Use pinch to zoom for a better view

### "Dimension labels overlap"

- This can happen with very small walls
- Solution: Zoom in to see labels more clearly

## Examples

### Example 1: Simple L-Shaped Room (5m × 4m with 2m × 2m cutout)

```
Points to place (in order):
1. (0, 0) - Bottom left
2. (6000, 0) - Bottom right
3. (6000, 4000) - Top right
4. (2000, 4000) - Inner corner top
5. (2000, 2000) - Inner corner middle
6. (0, 2000) - Left side middle
→ Close back to point 1
```

Result: 16 m² usable area

### Example 2: Hallway with Alcove

```
Main hall: 8m × 2m
Alcove: 1m × 1m at 4m mark

Points:
1. (0, 0)
2. (8000, 0)
3. (8000, 2000)
4. (4500, 2000) - Alcove start
5. (4500, 3000) - Alcove depth
6. (3500, 3000) - Alcove width
7. (3500, 2000) - Alcove end
8. (0, 2000)
→ Close
```

## Best Practices

1. **Measure First**: Have your actual room measurements ready
2. **Draw Accurately**: Use the grid to ensure straight walls
3. **Check Area**: Verify the calculated area matches your expectations
4. **Test Layout**: Generate a layout to see how pieces fit
5. **Save Project**: Save after designing to keep your custom room

## Future Enhancements

Coming soon:
- Adjustable grid size
- Manual dimension entry for each wall
- Import from CAD/DXF files
- Curved walls support
- Auto-detect right angles
- Measurement tools (distance, angle)
- Snap to previous points

---

**Need Help?**

- The status bar shows your current progress
- Instructions update as you draw
- Use "Undo" freely - there's no limit

**Pro Tip:** For complex rooms, sketch on paper first with measurements, then replicate in the designer. This ensures accuracy and saves time.
