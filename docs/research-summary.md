# Research Summary

## Sources Reviewed
- `learnings/07-llm-integration-guide.md`
- Gemini API references:
  - `https://ai.google.dev/api/generate-content`
  - `https://ai.google.dev/api/models`
- Vertex AI documentation navigation (model availability references):
  - `https://docs.cloud.google.com/vertex-ai/generative-ai/docs`

## Key Findings
- Gemini API supports multimodal inputs via `models.generateContent`, with explicit image examples and MIME types like `image/jpeg`.
- The API includes `models.list` and `models.get` endpoints for model discovery and metadata.
- The internal LLM guide recommends:
  - Structured prompts and strict output formats for reliable parsing.
  - Retry with exponential backoff on failures.
  - Avoiding key exposure by keeping API calls server-side.
  - Caching by image hash to reduce costs and duplicates.

## Implications for the MVP
- Use a tiny proxy (Cloud Functions 2nd gen) for Gemini calls to avoid exposing the API key in the app.
- Implement a strict JSON output schema to reduce parsing ambiguity.
- Use retries on the server, and a user-facing retry button on the client.
- Keep prompts concise and structured to control cost and latency.

## Gaps / Constraints
- The Gemini documentation pages are JS-rendered; the API reference pages are readable and confirm the key request format but do not provide all model details inline.
- The plan assumes Gemini Pro 3 supports image understanding; this should be verified in the GCP console or AI Studio before implementation.
