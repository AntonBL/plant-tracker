# High-Level Goal

Build a lightweight, iOS-first plant tracker that can analyze plant photos with Gemini 3 Flash Preview and help the user set watering cadence. Data stays on-device; AI calls go through a tiny GCP Cloud Functions (2nd gen) proxy to protect the API key. The app should feel fast, simple, and usable end-to-end with minimal setup.

Key outcomes:
- Take or select a plant photo, get an AI health assessment and recommendations.
- Let the user set alert cadence manually (AI can recommend, user decides).
- Per-plant chat with the AI for guidance.
- Local notifications for watering reminders.

Non-goals for MVP:
- No backend database or multi-user sync.
- No manual fallback logic beyond retry when AI fails.
- No web or Android app.
