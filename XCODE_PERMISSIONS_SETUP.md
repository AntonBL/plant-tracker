# Xcode Permissions Setup Required

## Camera and Photo Library Permissions

The following permissions need to be added manually in Xcode:

### Steps:
1. Open `PlantTracker.xcodeproj` in Xcode
2. Select the `PlantTracker` target in the project navigator
3. Go to the "Info" tab
4. Add the following keys under "Custom iOS Target Properties":

### Required Privacy Keys:

**NSCameraUsageDescription**
- **Value**: `PlantTracker needs camera access to take photos of your plants for health analysis.`
- **Type**: String

**NSPhotoLibraryUsageDescription**
- **Value**: `PlantTracker needs access to your photo library to select plant images.`
- **Type**: String

### Alternative: Edit Info.plist directly

If an Info.plist file exists, add these entries:

```xml
<key>NSCameraUsageDescription</key>
<string>PlantTracker needs camera access to take photos of your plants for health analysis.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PlantTracker needs access to your photo library to select plant images.</string>
```

## Note
Without these permissions, the app will crash when trying to access the camera or photo library.
