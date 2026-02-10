# Building Floor Planner in Xcode

This guide explains how to build the Floor Planner app in Xcode 15 or later.

## Quick Start

### Option 1: Open Existing Project (Recommended)

1. Open `FloorPlanner.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Select the target device (iPhone, iPad, or My Mac)
4. Click Run (⌘R)

### Option 2: Create New Project from Source

If you prefer to create a fresh Xcode project:

1. **Create New Project**
   - Open Xcode
   - File → New → Project
   - Select "Multiplatform" → "App"
   - Name: "FloorPlanner"
   - Interface: SwiftUI
   - Language: Swift
   - Click "Next" and save

2. **Add Source Files**
   - Delete the default `ContentView.swift` and app file
   - Drag all `.swift` files from the `FloorPlanner/` directory into your project
   - Ensure "Copy items if needed" is checked
   - Select "FloorPlanner" as the target

3. **Configure Info.plist**
   - Delete the auto-generated `Info.plist` if present
   - Add the `Info.plist` from the `FloorPlanner/` directory to your project
   - In project settings → Info tab, set "Custom iOS Target Properties" to use this file

4. **Add Entitlements**
   - Add `FloorPlanner.entitlements` to your project
   - In project settings → Signing & Capabilities:
     - Click "+ Capability"
     - Add "File Access" → "User Selected Files" (Read/Write)

5. **Configure Build Settings**
   - Select the FloorPlanner project in the navigator
   - Select the target
   - General tab:
     - Set minimum iOS version to 16.0
     - Set minimum macOS version to 13.0
   - Signing & Capabilities:
     - Select your development team
     - Enable "Supports Mac Catalyst"
   
6. **Build and Run**
   - Select target device or simulator
   - Press ⌘R to build and run

## Project Configuration Details

### Supported Platforms

- **iOS**: iPhone and iPad (iOS 16.0+)
- **macOS**: Mac via Mac Catalyst (macOS 13.0+)

### Required Capabilities

- **File Access**: User-selected read/write for document export

### Build Targets

The project includes two targets:

1. **FloorPlanner** (Main App)
   - All Swift source files
   - Info.plist
   - Entitlements file

2. **FloorPlannerTests** (Unit Tests)
   - Test files from `Tests/FloorPlannerTests/`

## File Structure

```
FloorPlanner/
├── FloorPlannerApp.swift       # App entry point (@main)
├── ContentView.swift            # Main adaptive view
├── Models.swift                 # Data models
├── LayoutEngine.swift          # Layout protocol
├── LaminateEngine.swift        # Laminate algorithm
├── TileEngine.swift            # Tile algorithm
├── PersistenceManager.swift    # Save/load/export
├── MaterialPickerView.swift    # Material selection
├── RoomSettingsView.swift      # Room configuration
├── StockTableView.swift        # Stock management
├── MaterialSettingsView.swift  # Material options
├── PreviewView.swift           # 2D preview canvas
├── ReportsView.swift           # Reports display
├── Info.plist                  # App configuration
└── FloorPlanner.entitlements   # Permissions

Tests/
└── FloorPlannerTests/
    └── FloorPlannerTests.swift # Unit tests
```

## Running Tests

### In Xcode

1. Press ⌘U to run all tests
2. Or: Product → Test

### From Command Line

```bash
# Build
xcodebuild -scheme FloorPlanner -destination 'platform=iOS Simulator,name=iPhone 15' build

# Test
xcodebuild -scheme FloorPlanner -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Common Issues and Solutions

### Issue: Code signing error

**Solution**: 
- Go to Signing & Capabilities
- Select your development team
- Or use "Automatically manage signing"

### Issue: Mac Catalyst build fails

**Solution**:
- Ensure macOS deployment target is 13.0 or later
- Check that "Supports Mac Catalyst" is enabled in General → Deployment Info

### Issue: File access permissions not working

**Solution**:
- Verify `FloorPlanner.entitlements` is in your project
- Check it's selected in Signing & Capabilities → App Sandbox
- Ensure "User Selected File" has Read/Write access

### Issue: SwiftUI preview crashes

**Solution**:
- Previews are not fully implemented for complex multi-view apps
- Build and run on simulator/device instead
- Or add preview providers to individual views

## Debugging

### Enable Debug Logging

The app prints debug information to the console for:
- Layout generation
- Stock calculations
- Export operations

View console output in Xcode: View → Debug Area → Show Debug Area (⇧⌘Y)

### Breakpoints

Useful places to set breakpoints:
- `LaminateEngine.generateLayout` - Laminate algorithm
- `TileEngine.generateLayout` - Tile algorithm
- `AppState.generateLayout` - Layout trigger
- `PersistenceManager.saveProject` - Save operations

## Performance

### Optimization Tips

1. **Large Rooms**: Layout generation is O(n) where n is number of pieces
2. **Stock Lists**: Larger stock lists increase search time
3. **Preview**: Canvas rendering is efficient but zooming large layouts may lag

### Profiling

Use Instruments to profile:
1. Product → Profile (⌘I)
2. Select "Time Profiler" or "Allocations"
3. Focus on layout generation methods

## Deployment

### iOS App Store

1. Archive: Product → Archive
2. Validate: Window → Organizer → Validate App
3. Upload: Distribute App → App Store Connect

### Mac App Store

1. Ensure Mac Catalyst is enabled
2. Create Mac-specific icons if needed
3. Archive and distribute as above

### TestFlight

1. Archive the app
2. Upload to App Store Connect
3. Enable TestFlight testing
4. Invite testers via email

## Advanced Configuration

### Custom Bundle ID

Change in project settings:
- General → Identity → Bundle Identifier
- Update to your domain (e.g., com.yourcompany.FloorPlanner)

### App Icons

Add icons to Assets.xcassets:
- iOS: 1024×1024 plus standard sizes
- Mac: Additional Mac icon sizes
- Use Xcode's asset catalog for automatic resizing

### Launch Screen

Customize in:
- Info.plist → UILaunchScreen
- Or add LaunchScreen.storyboard for custom design

### Localization

To add languages:
1. Project settings → Info → Localizations
2. Add language
3. Localize strings using String catalogs

## Support and Troubleshooting

### System Requirements

- **Development**: macOS 13.5+ with Xcode 15+
- **Runtime**: iOS 16+ or macOS 13+ (Catalyst)

### Clean Build

If experiencing build issues:
1. Product → Clean Build Folder (⇧⌘K)
2. Delete DerivedData: ~/Library/Developer/Xcode/DerivedData
3. Restart Xcode
4. Rebuild

### Resetting Simulator

If app behaves strangely in simulator:
1. Device → Erase All Content and Settings
2. Or: Delete app and reinstall

## Next Steps

- Customize default values in `Models.swift`
- Add app icons in Assets.xcassets
- Implement full export functionality in `PreviewView.swift` and `ReportsView.swift`
- Add more unit tests in `FloorPlannerTests.swift`
- Customize UI colors and styling
- Add user preferences/settings
- Implement undo/redo
- Add more room shape options (L-shaped, etc.)

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Mac Catalyst Guide](https://developer.apple.com/documentation/uikit/mac_catalyst)
- [Xcode Help](https://help.apple.com/xcode/)
