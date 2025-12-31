# AGENTS Instructions

## Scope
- iOS-only app with local storage (SwiftData).
- Gemini 3 Flash Preview used for all AI (image analysis + chat).
- AI calls go through a GCP Cloud Functions (2nd gen) proxy.
- No manual fallback logic. If AI fails, show a retry prompt.
- Per-plant chat only (no global chat).

## Architecture
- SwiftUI + MVVM.
- SwiftData models:
  - Plant
  - Assessment
  - WateringEvent
  - ChatMessage
- Networking layer uses a single `GeminiProxyClient`.
- Local notifications only; cadence is always user-set.

## Xcode Project Management
- **IMPORTANT**: When creating new Swift files, always remind the user to add them to the Xcode target.
- New files must be manually added in Xcode:
  1. Right-click on the appropriate folder in Xcode project navigator
  2. Select "Add Files to PlantTracker..."
  3. Select the new file(s)
  4. Ensure "PlantTracker" target is checked
  5. Click "Add"
- Without this step, files will exist on disk but won't compile or be accessible in the app.

## Proxy Requirements (GCP)
- Endpoints:
  - `POST /analyze` -> returns structured JSON assessment.
  - `POST /chat` -> returns structured JSON chat response.
- Gemini Pro 3 for all calls.
- Strict JSON response parsing and validation.
- Retry with exponential backoff; return clear retryable errors.
- API key stored in Secret Manager; never shipped in app.

## AI Prompting
- Use concise, structured prompts.
- Require strict JSON output.
- Include plant context (name, species, season, last watered) when available.
- Do not include user-identifying data.

## UX Rules
- User always sets alert cadence manually.
- AI may recommend cadence, but it is never auto-applied.
- On AI failure, show error and a retry button only.

## Testing
- Unit tests for cadence and notification scheduling.
- Mock proxy responses for UI tests.
- No flaky tests; avoid network in unit tests.

## Security + Privacy
- No API keys or secrets in the app bundle.
- Do not log raw images or personal data.
- Store photos and chat locally only.

## References
- `docs/high-level-goal.md`
- `docs/prd.md`
- `docs/research-summary.md`
- `docs/plan.md`
- `docs/task-breakdown.md`
- `docs/api-contract.md`
- `docs/prompt-library.md`
- `learnings/07-llm-integration-guide.md`
- `learnings/04-swiftui-frontend-guide.md`
