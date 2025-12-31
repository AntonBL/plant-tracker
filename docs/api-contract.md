# API Contract Appendix

## Overview
This proxy exposes two endpoints:
- `POST /analyze` for photo-based health assessment.
- `POST /chat` for per-plant chat responses.

All responses are JSON. All errors should be non-2xx with a retryable message.

---

## POST /analyze

### Request
```json
{
  "image_base64": "<base64-encoded-jpeg>",
  "plant_name": "Monstera",
  "species": "Monstera deliciosa",
  "season": "winter",
  "last_watered": "2025-01-15"
}
```

### Response (200)
```json
{
  "status": "needs_attention",
  "confidence": 0.82,
  "issues": [
    "Leaves show mild yellowing",
    "Soil looks dry"
  ],
  "recommendations": [
    "Water thoroughly and allow excess to drain",
    "Increase indirect light exposure"
  ],
  "suggested_interval_days": 6,
  "rationale": "Dry soil and yellowing suggest mild under-watering. Shorten interval slightly."
}
```

### Response (error)
```json
{
  "error": "analysis_failed",
  "message": "Gemini request failed. Please retry.",
  "retryable": true
}
```

---

## POST /chat

### Request
```json
{
  "messages": [
    {"role": "user", "content": "Is my plant okay?"},
    {"role": "assistant", "content": "What symptoms are you seeing?"},
    {"role": "user", "content": "Leaves are yellowing."}
  ],
  "plant_context": {
    "plant_name": "Monstera",
    "species": "Monstera deliciosa",
    "last_assessment_status": "needs_attention"
  }
}
```

### Response (200)
```json
{
  "reply": "Yellowing can indicate overwatering or low light. Check soil moisture and reduce watering if soil is damp.",
  "action_suggestions": [
    "Check soil moisture before watering",
    "Ensure bright, indirect light"
  ],
  "safety_note": "If the plant shows rapid decline, consider seeking expert advice."
}
```

### Response (error)
```json
{
  "error": "chat_failed",
  "message": "Gemini request failed. Please retry.",
  "retryable": true
}
```

---

## Notes
- Image must be JPEG and base64 encoded.
- Size limits are only enforced if `MAX_IMAGE_BYTES` is configured on the proxy.
- All timestamps should be ISO-8601 when used.
