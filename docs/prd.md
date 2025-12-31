# Product Requirements Document (PRD)

## Summary
An iOS-only plant tracker that uses Gemini 3 Flash Preview to analyze plant photos and provide health guidance. The user sets watering cadence manually based on AI suggestions. All data is stored locally using SwiftData. Gemini API access is handled by a tiny GCP Cloud Functions (2nd gen) proxy to protect the API key.

## Target Users
- Primary: Individual plant owners who want quick health checks and reminders.
- Secondary: Friends testing the MVP.

## Goals
- End-to-end flow: add plant -> take photo -> AI assessment -> set cadence -> get reminders.
- Per-plant chat with AI for care guidance.
- Minimal setup and fast iteration.

## Non-Goals
- Multi-user accounts or data sync.
- Advanced analytics or long-term trends.
- Manual fallback diagnostics when AI fails (retry only).
- Web or Android clients.

## User Stories
- As a user, I can add a plant with a name, optional species, and a photo.
- As a user, I can request an AI assessment from a plant photo.
- As a user, I can chat with the AI about a specific plant.
- As a user, I can set and update watering cadence manually.
- As a user, I receive local notifications based on my cadence.

## Functional Requirements
### iOS App
- Plant CRUD with local persistence (SwiftData).
- Photo capture or selection (PhotosPicker).
- Upload photo to proxy for analysis.
- Display AI results: status, confidence, issues, recommendations, suggested interval.
- Per-plant chat UI with history stored locally.
- Manual watering cadence input and local scheduling.
- Local notifications; reschedule on cadence updates or "Watered now" action.
- Retry UI for failed AI calls.

### Proxy (GCP Cloud Functions 2nd gen)
- `POST /analyze`
  - Input: base64 JPEG + plant context.
  - Output: structured JSON assessment.
- `POST /chat`
  - Input: message list + plant context.
  - Output: structured JSON chat response.
- Gemini 3 Flash Preview integration for both endpoints.
- Structured prompts; strict JSON response parsing and validation.
- Error handling with retries and clear error responses.
- Secret Manager for API key.

## Non-Functional Requirements
- Latency: < 5s average for analysis and chat (best effort).
- Reliability: clear errors and retry options if Gemini fails.
- Security: no API keys in the app; no raw image logs.
- Privacy: keep plant data local; proxy only processes image for the request.

## Success Metrics
- 80% of photo analyses succeed within 2 tries.
- User completes the full flow within 2 minutes.
- At least 1 reminder successfully scheduled after analysis.

## Dependencies
- Google Cloud project with billing enabled.
- Gemini 3 Flash Preview API access.
- Apple Photos access and Notification permissions.

## Open Questions
- Default alert cadence suggestion if Gemini response omits it?
- Any compliance requirements for storing photos locally?

## Related Docs
- `docs/api-contract.md`
