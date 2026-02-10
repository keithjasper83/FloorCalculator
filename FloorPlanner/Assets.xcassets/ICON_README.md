# App Icon Instructions

## Quick Start

Place your 1024×1024 app icon in:
```
FloorPlanner/Assets.xcassets/AppIcon.appiconset/
```

Name it: `icon_1024x1024.png`

Xcode will automatically generate other sizes.

## Icon Design Suggestions

### Concept
The app is for floor planning, so consider icons featuring:
- Floor plan grid
- Measuring tools
- Floor tiles/planks
- Blueprint style design
- Geometric patterns

### Design Guidelines

**Style**: Simple, modern, flat design
**Colors**: Blue/gray (professional), or warm wood tones
**Background**: Solid color or subtle gradient
**Text**: None (icons work better without text)
**Margins**: Keep important elements 10% from edges

### Example Concepts

1. **Grid Pattern Icon**
   - Simple 3×3 grid of squares
   - One square highlighted in accent color
   - Clean, minimal look

2. **Measuring Tool**
   - Stylized ruler or measuring tape
   - Corner angle icon
   - Blueprint with measurements

3. **Floor Tiles**
   - Abstract representation of floor tiles
   - Parquet pattern
   - Staggered plank design

## Creating Your Icon

### Option 1: Design Tool

Use Figma, Sketch, Adobe Illustrator, or similar:

1. Create 1024×1024 artboard
2. Design your icon
3. Export as PNG
4. Save to AppIcon.appiconset folder

### Option 2: Icon Generator Services

Use online services (they handle all sizes):
- [AppIcon.co](https://appicon.co)
- [MakeAppIcon](https://makeappicon.com)
- [AppIconizer](https://appiconizer.com)

Steps:
1. Upload your 1024×1024 image
2. Generate icon set
3. Download and extract
4. Replace contents of AppIcon.appiconset

### Option 3: Placeholder (For Testing)

For now, use a simple solid color:

```bash
# Create solid blue 1024x1024 PNG (macOS)
sips -Z 1024 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns --out icon_1024x1024.png
```

Or create in any image editor.

## Required Sizes

The Assets catalog needs these sizes:

### iOS / iPadOS
- 1024×1024 (App Store)

### macOS
- 16×16 @1x, @2x
- 32×32 @1x, @2x
- 128×128 @1x, @2x
- 256×256 @1x, @2x
- 512×512 @1x, @2x

Xcode generates these automatically from the 1024×1024 image.

## Checklist

- [ ] Icon is 1024×1024 pixels
- [ ] PNG format
- [ ] RGB color space (not CMYK)
- [ ] No transparency (solid background)
- [ ] Looks good when scaled down
- [ ] Follows App Store guidelines
- [ ] No rounded corners (iOS adds them)
- [ ] High contrast and visible

## Testing Your Icon

1. Add icon to Assets.xcassets
2. Build and run app
3. Check home screen on device/simulator
4. Check app switcher
5. Check Settings
6. Check different device sizes

## App Store Guidelines

Your icon must:
- Be square
- Not include rounded corners
- Not include iOS interface elements
- Not use Apple trademarks
- Be at least 1024×1024 pixels
- Be in RGB color space
- Not have alpha channel/transparency

For complete guidelines:
https://developer.apple.com/design/human-interface-guidelines/app-icons

## Current Status

✅ Asset catalog created
✅ AppIcon placeholder ready
⏳ Need 1024×1024 icon image

**Next step**: Add your icon image to AppIcon.appiconset folder.
