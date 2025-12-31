# Xcode Setup Checklist

Use this to verify your Xcode project is configured correctly.

## ✅ Pre-Build Checklist

- [ ] Xcode project opened: `PlantTracker/PlantTracker/PlantTracker.xcodeproj`
- [ ] Default ContentView.swift and PlantTrackerApp.swift deleted (the Xcode-generated ones)
- [ ] All source folders added to project (Models, Views, ViewModels, Services, Utilities, PlantTrackerApp.swift)
- [ ] Files show up in Xcode navigator (left sidebar)
- [ ] Minimum iOS version set to 17.0 (General tab)
- [ ] Info.plist has photo and camera permissions
- [ ] Constants.swift updated with Cloud Function URL: `https://plant-proxy-ozg2qzyl6q-uc.a.run.app`

## ✅ Build Checklist

- [ ] Build succeeds (Cmd+B) with no errors
- [ ] All 26 Swift files compile
- [ ] No "Cannot find type" errors
- [ ] No "Module not found" errors

## ✅ First Run Checklist

- [ ] App launches in simulator
- [ ] Shows "No Plants Yet" empty state
- [ ] "+" button visible in top right
- [ ] No crashes on launch

## ✅ Add Plant Flow Test

- [ ] Tap "+" button
- [ ] "Add Plant" sheet appears
- [ ] Can enter plant name
- [ ] Can select photo from library
- [ ] "Analyze Plant Health" button appears after photo selected
- [ ] Permission prompt appears for photo library (first time)

## ✅ Full Integration Test

- [ ] Select a plant photo
- [ ] Enter plant name (e.g., "Test Monstera")
- [ ] Tap "Analyze Plant Health"
- [ ] Loading indicator shows
- [ ] Analysis results appear with:
  - Health status (healthy/needs_attention/critical)
  - Confidence percentage
  - Issues list
  - Recommendations list
- [ ] Can set watering cadence
- [ ] Tap "Save Plant"
- [ ] Plant appears in list
- [ ] Can tap plant to see details

## 🐛 Troubleshooting

### Build Errors

**"Cannot find 'Plant' in scope"**
1. Select file in navigator
2. Open File Inspector (right sidebar, Cmd+Opt+1)
3. Check "Target Membership" → PlantTracker should be checked

**"Multiple commands produce Assets.xcassets"**
1. Select project in navigator
2. Build Phases tab
3. Check "Copy Bundle Resources" - should only have ONE Assets.xcassets

**SwiftData errors**
1. Verify iOS deployment target is 17.0+
2. Make sure all @Model macros are correct

### Runtime Errors

**"Invalid proxy URL"**
- Check Constants.swift has correct URL
- Rebuild after changing Constants.swift

**"Network request failed"**
- Verify Cloud Function is deployed: `gcloud functions describe plant-proxy --gen2 --region=us-central1`
- Test URL in browser: should return method not allowed (it only accepts POST)
- Check Cloud Function logs: `gcloud functions logs read plant-proxy --gen2`

**Photo picker doesn't open**
- Check Info.plist has photo permissions
- Simulator: Use Cmd+Shift+H → Photos app to add test photos first

**"Analysis failed" every time**
- Check Cloud Function logs for errors
- Verify Gemini API key is valid in Secret Manager
- Test with curl (see DEPLOYMENT.md)

### Permission Issues

**Photo permission denied**
1. iOS Simulator → Settings → Privacy & Security → Photos
2. Find PlantTracker
3. Set to "All Photos"

**Notification permission**
- First plant add will prompt
- If denied, go to Settings → PlantTracker → Notifications

## 📊 Success Criteria

Your app is working when:
- ✅ Can add a plant with photo
- ✅ AI analysis returns results
- ✅ Can save plant with cadence
- ✅ Plant shows in list
- ✅ Can view plant details
- ✅ Can chat with AI about plant
- ✅ "Water Now" button works
- ✅ Notification scheduled (check Notification Center after cadence time)

## 🎯 Next Steps After Success

1. Test with real plant photos
2. Add multiple plants
3. Test watering workflow
4. Try the chat feature
5. Wait for a notification (or set short cadence for testing)

## 📸 Test Images

In the `test-images/` folder you have sample plant images for testing. Use these if you don't have plant photos handy.

## 🚀 You're Ready!

Once all checkboxes are ✅, you have a fully functional AI-powered plant tracker!
