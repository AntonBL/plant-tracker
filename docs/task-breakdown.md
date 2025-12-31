# Task Breakdown

## Milestone 1: Contract + Prompt Definitions
**Tasks**
- Define JSON schema for assessment.
- Define JSON schema for chat response.
- Write structured prompts for analysis and chat.
- Confirm Gemini Pro 3 supports image inputs.

**Acceptance Criteria**
- Schemas documented and aligned with UI needs.
- Prompts are concise and output strictly in JSON.
- Gemini model availability confirmed in GCP console/AI Studio.

---

## Milestone 2: GCP Cloud Functions Proxy
**Tasks**
- Create Cloud Function (2nd gen) with `POST /analyze` and `POST /chat`.
- Integrate Gemini 3 Flash Preview calls.
- Validate and parse JSON responses.
- Implement retry with exponential backoff.
- Store API key in Secret Manager.

**Acceptance Criteria**
- `POST /analyze` returns valid assessment JSON for a sample image.
- `POST /chat` returns valid chat JSON for a sample prompt.
- Errors result in non-2xx responses and include a retryable message.
- API key is not present in source code or client.

---

## Milestone 3: iOS Data + Networking Layer
**Tasks**
- Define SwiftData models: Plant, Assessment, WateringEvent, ChatMessage.
- Implement `GeminiProxyClient` for `/analyze` and `/chat`.
- Add image compression utility.

**Acceptance Criteria**
- Models compile and persist locally.
- Proxy calls succeed with sample payloads.
- Images are reduced to acceptable upload size.

---

## Milestone 4: Core UI + Workflows
**Tasks**
- Plant list and add flow.
- Plant detail with assessment results.
- Chat view per plant.
- Manual cadence input and local notification scheduling.
- Retry UI for failed analysis/chat calls.

**Acceptance Criteria**
- User can add a plant, analyze a photo, and see results.
- User can chat with AI in a plant context.
- User can set cadence and receive a notification.
- Failed AI calls show a retry action.

---

## Milestone 5: QA + Polish
**Tasks**
- Unit tests for cadence and notification logic.
- Mock network responses for UI tests.
- Permissions checks for Photos and Notifications.

**Acceptance Criteria**
- Tests cover basic scheduling logic.
- App handles denied permissions gracefully.
- Core flow is stable across devices.
