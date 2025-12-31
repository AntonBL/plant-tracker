# GCP Cloud Functions Proxy (2nd gen)

## Overview
Two endpoints:
- `POST /analyze` for image assessment
- `POST /chat` for per-plant chat

## Environment Variables
- `GEMINI_API_KEY` (required)
- `GEMINI_MODEL` (default: gemini-3-flash-preview)
- `MAX_IMAGE_BYTES` (optional)

## Entry Point
Deploy with entry point `handle`.

## Notes
- This is a minimal stub for the MVP.
- Gemini model name should be verified in GCP console/AI Studio.
