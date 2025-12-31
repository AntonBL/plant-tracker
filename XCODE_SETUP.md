# PlantTracker - Xcode Project Setup

## Step 1: Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Configure project:
   - Product Name: `PlantTracker`
   - Team: (Your team)
   - Organization Identifier: `com.yourname` (or your domain)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we'll add SwiftData manually)
   - Include Tests: **Yes**
5. Choose location: This `plant-tracker` directory
6. Create

## Step 2: Delete Default Files

Xcode creates some default files. Delete these:
- `ContentView.swift` (we'll create our own)
- Any preview files

## Step 3: Add Source Files to Project

Drag the `PlantTracker/` folder (the one with Models, Views, etc.) into your Xcode project:

1. Right-click on `PlantTracker` group in Xcode navigator
2. Add Files to "PlantTracker"...
3. Select the `PlantTracker/` directory
4. Check "Create groups"
5. Check "Add to targets: PlantTracker"
6. Click Add

This will add all the Swift files we've created.

## Step 4: Configure Info.plist

Add these keys to your Info.plist:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Select plant photos for health analysis</string>

<key>NSCameraUsageDescription</key>
<string>Take plant photos for health analysis</string>
```

To add them in Xcode:
1. Select your target
2. Go to "Info" tab
3. Add these keys under "Custom iOS Target Properties"

## Step 5: Update Constants.swift

Open `PlantTracker/Utilities/Constants.swift` and update the proxy URL with your Cloud Function URL from the deployment step.

## Step 6: Build and Run

1. Select a simulator or device
2. Press Cmd+R to build and run

## Project Structure

After setup, your project should look like:

```
PlantTracker/
├── PlantTrackerApp.swift          # App entry point
├── Models/
│   ├── Plant.swift                # SwiftData model
│   ├── Assessment.swift           # SwiftData model
│   ├── WateringEvent.swift        # SwiftData model
│   ├── ChatMessage.swift          # SwiftData model
│   └── ProxyDTOs.swift            # Network DTOs
├── Views/
│   ├── ContentView.swift          # Root view
│   ├── PlantListView.swift        # Plant list
│   ├── AddPlantView.swift         # Add plant flow
│   ├── PlantDetailView.swift      # Plant details
│   ├── AnalysisResultView.swift   # Analysis results
│   ├── ChatView.swift             # AI chat
│   └── Components/
│       ├── PlantRowView.swift     # List row
│       └── RetryButton.swift      # Retry UI
├── ViewModels/
│   ├── PlantListViewModel.swift
│   ├── PlantDetailViewModel.swift
│   └── ChatViewModel.swift
├── Services/
│   ├── GeminiProxyClient.swift    # API client
│   ├── NotificationService.swift  # Notifications
│   └── ImageService.swift         # Image processing
└── Utilities/
    └── Constants.swift             # App constants
```

## Minimum iOS Version

This app requires **iOS 17+** for SwiftData support.

To set this:
1. Select your target
2. General tab
3. Minimum Deployments → iOS 17.0

## Troubleshooting

**Build errors about missing files:**
- Ensure all files are added to target (check File Inspector)

**SwiftData errors:**
- Verify iOS deployment target is 17.0+
- Check that models have `@Model` macro

**Network errors in simulator:**
- Check that proxy URL in Constants.swift is correct
- Verify Cloud Function is deployed and accessible
