# Xcode Setup & App Store Submission Guide

## Quick Start for Xcode 15.3+ / 16.x

### Step 1: Open Project

```bash
open FloorPlanner.xcodeproj
```

The project will open in Xcode. If you see any migration prompts, click "Continue" or "Perform Changes".

### Step 2: Configure Bundle Identifier & Team

**CRITICAL**: You must update the Bundle Identifier before building.

1. Click on **FloorPlanner** project in the navigator (blue icon at top)
2. Select **FloorPlanner** target
3. Go to **General** tab
4. Update **Bundle Identifier**: 
   - Change from: `com.floorplanner.app`
   - Change to: `com.YOURCOMPANY.FloorPlanner` or your preferred ID
   - **Must be unique** on App Store

5. Go to **Signing & Capabilities** tab
6. Select your **Team** from dropdown
7. Ensure **Automatically manage signing** is checked

### Step 3: Build & Run

1. Select target device from toolbar:
   - **iPhone** simulator (e.g., iPhone 15 Pro)
   - **iPad** simulator (e.g., iPad Pro 12.9")
   - **My Mac** (Mac Catalyst)

2. Press **⌘R** to build and run

3. If build fails:
   - Check team selection
   - Check bundle ID is unique
   - Clean build folder: **⌘⇧K**
   - Try again

## Bundle Identifier Requirements

### What You MUST Have

Your Bundle Identifier must:
- Be **unique** across all App Store apps
- Use **reverse DNS** format: `com.yourcompany.appname`
- Contain **only** letters, numbers, hyphens, periods
- Start with a letter after each period

### Examples

✅ Good:
```
com.acme.floorplanner
com.yourname.FloorPlanner
com.buildco.floorplanning
```

❌ Bad:
```
floorplanner (missing domain)
com.floorplanner.app (generic - likely taken)
com.-acme.app (starts with hyphen)
```

### How to Choose

1. **Own a domain?** Use: `com.yourdomain.FloorPlanner`
2. **Personal project?** Use: `com.yourname.FloorPlanner`
3. **Company?** Use: `com.companyname.FloorPlanner`

## Required Settings Verification

### Info.plist Keys ✅

The following keys are already configured:

- ✅ `CFBundleIdentifier` - Bundle ID (set in build settings)
- ✅ `CFBundleDisplayName` - "Floor Planner"
- ✅ `CFBundleShortVersionString` - 1.0
- ✅ `CFBundleVersion` - 1
- ✅ `LSApplicationCategoryType` - Productivity
- ✅ `NSHumanReadableCopyright` - Copyright notice
- ✅ `UIApplicationSceneManifest` - SwiftUI scenes
- ✅ `UISupportedInterfaceOrientations` - All orientations
- ✅ `ITSAppUsesNonExemptEncryption` - No encryption (expedites review)

### Entitlements ✅

The following entitlements are configured:

- ✅ `com.apple.security.files.user-selected.read-write` - File export

### Build Settings ✅

The following are configured:

- ✅ **Deployment Target**: iOS 17.0, macOS 14.0
- ✅ **Swift Version**: 5.0
- ✅ **Mac Catalyst**: Enabled
- ✅ **Supported Platforms**: iOS, iPadOS, macOS
- ✅ **Code Signing**: Automatic (you select team)
- ✅ **Hardened Runtime**: Enabled (Mac)

## Pre-Flight Checklist

Before submitting to App Store, verify:

### 1. Bundle Identifier
- [ ] Changed from default `com.floorplanner.app`
- [ ] Matches your Apple Developer account
- [ ] Registered in App Store Connect

### 2. Team & Signing
- [ ] Team selected in Xcode
- [ ] Provisioning profile valid
- [ ] Certificate valid (not expired)
- [ ] Automatic signing enabled

### 3. App Icons
- [ ] Create Assets.xcassets folder
- [ ] Add AppIcon asset
- [ ] Provide all required sizes:
  - 1024×1024 (App Store)
  - iOS sizes (60pt, 76pt, 83.5pt at @2x, @3x)
  - Mac size (512pt at @1x, @2x)

### 4. Version & Build
- [ ] Version number: 1.0 (or your version)
- [ ] Build number: 1 (increment for each upload)
- [ ] Update in Info.plist if changed

### 5. Testing
- [ ] Build succeeds on iOS Simulator
- [ ] Build succeeds on Mac
- [ ] All unit tests pass (⌘U)
- [ ] Manual testing on device
- [ ] Test all material types
- [ ] Test save/load functionality
- [ ] Test export functionality

### 6. App Store Connect
- [ ] Apple Developer account active
- [ ] App registered in App Store Connect
- [ ] Bundle ID matches exactly
- [ ] Screenshots prepared (see below)
- [ ] App description written
- [ ] Keywords selected
- [ ] Privacy policy URL (if collecting data)

## Adding App Icons

### Option 1: Use Xcode

1. Create **Assets.xcassets** in FloorPlanner folder
2. Right-click → **New App Icon**
3. Drag 1024×1024 image into "App Store" slot
4. Xcode generates other sizes automatically

### Option 2: Manual Setup

1. Create Assets.xcassets folder
2. Inside, create AppIcon.appiconset folder
3. Add Contents.json:

```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

4. Add icon images

## Screenshot Requirements

### iPhone (Required)
- 6.7" display (iPhone 15 Pro Max)
- 6.5" display (iPhone 11 Pro Max) 
- Minimum 3, maximum 10 screenshots
- Dimensions: 1290×2796 pixels or 1284×2778 pixels

### iPad (Required)
- 12.9" display (iPad Pro 12.9")
- Minimum 3, maximum 10 screenshots
- Dimensions: 2048×2732 pixels

### Mac (Optional but Recommended)
- Minimum 3, maximum 10 screenshots
- Dimensions: 1280×800 pixels or higher

### Taking Screenshots

1. Run app on simulator/device
2. Navigate to key screens
3. Press **⌘S** in simulator (or use Mac screenshot: ⌘⇧4)
4. Recommended screens:
   - Material selection dialog
   - Room configuration
   - Stock management
   - 2D preview with layout
   - Reports view

## Archive & Upload

### Step 1: Archive

1. Select **Any iOS Device** or **My Mac** from device menu
2. **Product → Archive**
3. Wait for archive to complete
4. Organizer window opens automatically

### Step 2: Validate

1. In Organizer, select your archive
2. Click **Validate App**
3. Select team
4. Click **Validate**
5. Fix any errors shown

### Step 3: Upload

1. Click **Distribute App**
2. Select **App Store Connect**
3. Click **Upload**
4. Select team and options
5. Click **Upload**
6. Wait for upload to complete

### Step 4: App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Create new version (if needed)
4. Fill in metadata:
   - App name
   - Subtitle
   - Description
   - Keywords
   - Screenshots (all sizes)
   - Support URL
   - Privacy policy URL (if applicable)
5. Select build (uploaded archive)
6. Complete App Review Information
7. Click **Submit for Review**

## Common Issues & Solutions

### Issue: "Failed to verify bitcode"
**Solution**: Bitcode is deprecated. Disable in build settings if present.

### Issue: "Provisioning profile doesn't include signing certificate"
**Solution**: 
1. Go to **Signing & Capabilities**
2. Uncheck **Automatically manage signing**
3. Check it again
4. Select team again

### Issue: "Bundle identifier is already in use"
**Solution**: Change bundle identifier to something unique to you.

### Issue: "Missing compliance"
**Solution**: In App Store Connect, answer export compliance questions. For this app, select "No" to encryption.

### Issue: "Missing required icon"
**Solution**: Add Assets.xcassets with AppIcon (see section above).

### Issue: "Invalid Bundle Structure"
**Solution**: 
1. Clean build folder (⌘⇧K)
2. Delete DerivedData
3. Archive again

### Issue: "Mac Catalyst build fails"
**Solution**: 
1. Verify macOS deployment target is 14.0
2. Check that Mac Catalyst is enabled in General tab
3. Ensure entitlements are valid for Mac

### Issue: "App doesn't open after install"
**Solution**: 
1. Check console logs in Xcode
2. Verify Info.plist is valid
3. Check for any missing frameworks
4. Ensure all Swift files are in target

## TestFlight (Recommended First)

Before App Store submission, use TestFlight:

1. Upload build (same as App Store process)
2. Go to TestFlight tab in App Store Connect
3. Add internal testers (your team)
4. Add external testers (optional)
5. Test app thoroughly
6. Gather feedback
7. Fix issues
8. Upload new build
9. Repeat until ready
10. Then submit to App Store

## App Review Tips

### Increase Approval Chances

1. **Test thoroughly**: No crashes
2. **Clear description**: Explain what app does
3. **Screenshots**: Show key features
4. **Demo account**: Not needed for this app
5. **Review notes**: Explain any special features
6. **Privacy**: This app collects no user data
7. **Age rating**: 4+ (general audience)

### Typical Review Time

- First submission: 24-48 hours
- Resubmissions: 12-24 hours
- Holiday periods: May be longer

### If Rejected

1. Read rejection reason carefully
2. Fix the issue
3. Respond to App Review team (if clarification needed)
4. Upload new build
5. Resubmit

## Post-Approval

### App Store Listing

Optimize for discovery:

1. **App Name**: "Floor Planner" or "Floor Planner - Layout Tool"
2. **Subtitle**: "Plan laminate & tile installations"
3. **Keywords**: flooring, floor, planner, layout, laminate, tile, carpet, installation, calculator, home improvement
4. **Category**: Productivity (or Business)
5. **Description**: Highlight key features (see USER_GUIDE.md)

### Pricing

Options:
- Free (recommended for v1.0)
- Paid ($0.99 - $9.99 suggested)
- Freemium (free with in-app purchases)

### Launch

1. Set availability date
2. Choose countries (worldwide recommended)
3. Enable App Store search
4. Share app link on social media
5. Ask for reviews

## Version Updates

For future versions:

1. Update version number in Info.plist
2. Increment build number
3. Make code changes
4. Test thoroughly
5. Archive & upload
6. Create new version in App Store Connect
7. Fill in "What's New" section
8. Submit for review

## Support & Resources

- **Xcode Help**: Help → Xcode Help
- **App Store Connect**: [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- **Developer Forums**: [https://developer.apple.com/forums/](https://developer.apple.com/forums/)
- **App Review Guidelines**: [https://developer.apple.com/app-store/review/guidelines/](https://developer.apple.com/app-store/review/guidelines/)
- **Human Interface Guidelines**: [https://developer.apple.com/design/human-interface-guidelines/](https://developer.apple.com/design/human-interface-guidelines/)

## Checklist Summary

Print this and check off before submission:

- [ ] Bundle ID changed from default
- [ ] Bundle ID registered in App Store Connect
- [ ] Team selected in Xcode
- [ ] App builds successfully on iOS
- [ ] App builds successfully on Mac
- [ ] All tests pass
- [ ] App icons added (all sizes)
- [ ] Screenshots taken (iPhone, iPad, Mac)
- [ ] App description written
- [ ] Keywords selected
- [ ] Support URL provided
- [ ] Privacy policy (if needed)
- [ ] Age rating appropriate (4+)
- [ ] Export compliance answered (No encryption)
- [ ] TestFlight testing completed
- [ ] Archive created
- [ ] App validated
- [ ] App uploaded
- [ ] Metadata completed in App Store Connect
- [ ] Submitted for review

---

**Good luck with your App Store submission!**

*This guide was created specifically for Floor Planner v1.0*
