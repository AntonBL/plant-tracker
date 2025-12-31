# Plan

## Phase 0: Define Contracts
- Define assessment JSON schema.
- Define chat JSON schema.
- Draft structured prompts for analysis and chat.
- Confirm Gemini Pro 3 model supports images in the chosen API.

## Phase 1: GCP Proxy (Cloud Functions 2nd gen)
- Create a Cloud Function with two endpoints:
  - `POST /analyze`
  - `POST /chat`
- Use Secret Manager for API keys.
- Implement Gemini 3 Flash Preview calls for both endpoints.
- Validate and parse JSON responses.
- Retry with exponential backoff, surface errors when retries fail.

## Phase 2: iOS Core
- SwiftUI + MVVM structure.
- SwiftData models for plants, assessments, watering events, chat messages.
- PhotosPicker integration and JPEG compression.
- API client to call the proxy.
- UI for analysis results + manual cadence setting.
- Local notifications based on cadence.

## Phase 3: AI Workflows
- Photo -> analysis -> show AI results.
- Per-plant chat with context.
- Retry UI for AI failures (no fallback output).

## Phase 4: Polish + QA
- Basic UI/UX pass for the core flow.
- Add unit tests for schedule logic and notification scheduling.
- Mock proxy for UI testing.
- Verify permissions flows (Photos, Notifications).
