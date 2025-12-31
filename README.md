# Plant Tracker

An iOS app that uses Gemini 3 Flash Preview AI to analyze plant health from photos and provide personalized care guidance.

## Features

- **AI Health Analysis**: Take a photo of your plant and get instant health assessment with confidence scores
- **Smart Recommendations**: Receive specific care recommendations based on your plant's condition
- **Watering Reminders**: Set custom watering cadences and get local notifications
- **AI Chat**: Ask questions about your plant's care in a conversational interface
- **Local Storage**: All plant data stays on your device using SwiftData

## Architecture

- **iOS App**: SwiftUI + MVVM pattern, iOS 17+
- **Backend**: GCP Cloud Functions (2nd gen) proxy for Gemini API
- **AI Model**: Gemini 3 Flash Preview for image analysis and chat
- **Storage**: SwiftData for local persistence

## Getting Started

### Prerequisites

1. **macOS** with Xcode 15+
2. **Google Cloud** account with billing enabled
3. **Gemini API key** from [Google AI Studio](https://ai.google.dev/)

### 1. Deploy the Server

Follow the instructions in [DEPLOYMENT.md](DEPLOYMENT.md) to deploy the GCP Cloud Function:

```bash
# Navigate to server directory
cd server/

# Deploy function
gcloud functions deploy plant-proxy \
  --gen2 \
  --runtime=python312 \
  --region=us-central1 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=handle \
  --set-secrets=GEMINI_API_KEY=gemini-api-key:latest \
  --set-env-vars=GEMINI_MODEL=gemini-3-flash-preview
```

Copy the function URL - you'll need it for the iOS app.

### 2. Set Up the iOS App

Follow the instructions in [XCODE_SETUP.md](XCODE_SETUP.md):

1. Open Xcode and create a new iOS App project named "PlantTracker"
2. Add the `PlantTracker/` source directory to your project
3. Update `PlantTracker/Utilities/Constants.swift` with your Cloud Function URL
4. Configure Info.plist for photo and notification permissions
5. Build and run!

## Project Structure

```
plant-tracker/
├── server/                    # GCP Cloud Functions proxy
│   ├── main.py               # Function entry point
│   ├── prompts.py            # AI prompt templates
│   └── requirements.txt      # Python dependencies
│
├── PlantTracker/             # iOS app source
│   ├── Models/               # SwiftData models
│   │   ├── Plant.swift
│   │   ├── Assessment.swift
│   │   ├── WateringEvent.swift
│   │   ├── ChatMessage.swift
│   │   └── ProxyDTOs.swift
│   ├── Views/                # SwiftUI views
│   │   ├── PlantListView.swift
│   │   ├── AddPlantView.swift
│   │   ├── PlantDetailView.swift
│   │   ├── AnalysisResultView.swift
│   │   ├── ChatView.swift
│   │   └── Components/
│   ├── ViewModels/           # MVVM view models
│   ├── Services/             # Business logic
│   │   ├── GeminiProxyClient.swift
│   │   ├── NotificationService.swift
│   │   └── ImageService.swift
│   └── Utilities/
│       └── Constants.swift
│
└── docs/                     # Documentation
    ├── prd.md
    ├── api-contract.md
    └── prompt-library.md
```

## Core Workflows

### Add a Plant

1. Tap "+" in the plant list
2. Enter plant name and optional species
3. Select a photo from your library
4. Tap "Analyze Plant Health"
5. Review AI assessment (status, issues, recommendations)
6. Set watering cadence (or use AI suggestion)
7. Save plant

### Water a Plant

1. Open plant detail view
2. Tap "Water Now"
3. Watering event is logged and next notification is scheduled

### Chat with AI

1. Open plant detail view
2. Tap "Chat with AI"
3. Ask questions about your plant's care
4. Get personalized responses with action suggestions

## API Endpoints

The GCP proxy exposes two endpoints:

### POST /analyze

Analyze plant health from image.

**Request:**
```json
{
  "image_base64": "<base64-jpeg>",
  "plant_name": "Monstera",
  "species": "Monstera deliciosa",
  "season": "winter",
  "last_watered": "2025-01-15"
}
```

**Response:**
```json
{
  "status": "needs_attention",
  "confidence": 0.82,
  "issues": ["Leaves show mild yellowing"],
  "recommendations": ["Water thoroughly"],
  "suggested_interval_days": 6,
  "rationale": "Dry soil suggests under-watering"
}
```

### POST /chat

Chat with AI about plant care.

**Request:**
```json
{
  "messages": [
    {"role": "user", "content": "Why are my leaves yellow?"}
  ],
  "plant_context": {
    "plant_name": "Monstera",
    "species": "Monstera deliciosa",
    "last_assessment_status": "needs_attention"
  }
}
```

**Response:**
```json
{
  "reply": "Yellowing can indicate overwatering...",
  "action_suggestions": ["Check soil moisture"],
  "safety_note": "If rapid decline, seek expert advice"
}
```

## Key Design Decisions

### Why GCP Cloud Functions?
- Protects Gemini API key from client exposure
- Serverless = no infrastructure management
- Built-in retry logic and error handling
- Image caching to reduce costs

### Why SwiftData?
- Modern declarative data modeling
- Native Swift syntax
- Automatic persistence
- Relationships and cascade deletes

### Why Local Storage?
- No backend required for MVP
- Fast and responsive
- Works offline
- Privacy-focused (data stays on device)

### AI Strategy
- **Analysis**: Structured JSON output for reliable parsing
- **Chat**: Conversational with action suggestions
- **Prompts**: Include plant context (name, species, season)
- **Retry**: User-facing retry button on failures

## Cost Optimization

- **Gemini 3 Flash Preview**: Cost-effective model choice
- **Image Compression**: Reduce upload size (max 5MB)
- **Response Caching**: SHA256 hash to avoid duplicate analyses
- **No Streaming**: Simple request/response pattern

## Security & Privacy

- API key stored in GCP Secret Manager (never in app)
- Photos stored locally only
- No user accounts or authentication
- Proxy validates and sanitizes inputs

## Troubleshooting

### "Analysis Failed" Error
- Check that Cloud Function is deployed and accessible
- Verify proxy URL in `Constants.swift` is correct
- Check Cloud Function logs: `gcloud functions logs read plant-proxy --gen2`

### Build Errors in Xcode
- Ensure iOS deployment target is 17.0+
- Verify all files are added to target
- Clean build folder (Cmd+Shift+K)

### Notifications Not Showing
- Check notification permissions in Settings
- Verify cadence is set for the plant
- Check that `lastWatered` date is set

## Testing

The app includes preview providers for all views. To test:

1. Use Xcode Previews (Cmd+Opt+P) for rapid UI iteration
2. Run in simulator to test full flows
3. Test on device for notifications and photo library access

## Future Enhancements

- Unit tests for business logic
- UI tests for critical flows
- Species identification from photos
- Plant care history charts
- Export/import plant data
- iCloud sync between devices

## Resources

- [Gemini API Documentation](https://ai.google.dev/api)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)

## License

This project is for personal use.

## Contributing

This is a personal project, but suggestions and feedback are welcome!

---

Built with SwiftUI, SwiftData, and Gemini 3 Flash Preview
