from __future__ import annotations

import base64
import hashlib
import json
import os
import time
from collections import OrderedDict
from typing import Any, Callable, Dict, Tuple

from google import genai
from google.genai import types

from prompts import build_analyze_prompt, build_chat_prompt

MAX_IMAGE_BYTES = os.getenv("MAX_IMAGE_BYTES")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3-flash-preview")
CACHE_MAX_SIZE = int(os.getenv("CACHE_MAX_SIZE", "100"))
CACHE_TTL_SECONDS = int(os.getenv("CACHE_TTL_SECONDS", "3600"))  # 1 hour default

_client: genai.Client | None = None


class LRUCache:
    """Simple LRU cache with TTL support."""

    def __init__(self, max_size: int = 100, ttl_seconds: int = 3600):
        self._cache: OrderedDict[str, Tuple[Dict[str, Any], float]] = OrderedDict()
        self._max_size = max_size
        self._ttl_seconds = ttl_seconds

    def get(self, key: str) -> Dict[str, Any] | None:
        if key not in self._cache:
            return None
        value, timestamp = self._cache[key]
        if time.time() - timestamp > self._ttl_seconds:
            del self._cache[key]
            return None
        # Move to end (most recently used)
        self._cache.move_to_end(key)
        return value

    def set(self, key: str, value: Dict[str, Any]) -> None:
        if key in self._cache:
            self._cache.move_to_end(key)
        self._cache[key] = (value, time.time())
        # Evict oldest if over capacity
        while len(self._cache) > self._max_size:
            self._cache.popitem(last=False)


_analysis_cache = LRUCache(max_size=CACHE_MAX_SIZE, ttl_seconds=CACHE_TTL_SECONDS)


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY is not set")
        _client = genai.Client(api_key=api_key)
    return _client


def _json_response(payload: dict[str, Any], status: int = 200):
    return (
        json.dumps(payload),
        status,
        {"Content-Type": "application/json"},
    )


def _error_response(code: str, message: str, status: int = 500):
    return _json_response(
        {"error": code, "message": message, "retryable": True},
        status,
    )


def _call_with_retry(func: Callable[[], dict[str, Any]], max_retries: int = 2) -> dict[str, Any]:
    delay = 0.8
    for attempt in range(max_retries + 1):
        try:
            return func()
        except Exception:
            if attempt == max_retries:
                raise
            time.sleep(delay)
            delay *= 2
    raise RuntimeError("unreachable")


def _extract_text(response: Any) -> str:
    text = getattr(response, "text", None)
    if text:
        return text
    try:
        return response.candidates[0].content.parts[0].text
    except Exception:
        return ""


def _extract_json(text: str) -> dict[str, Any]:
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("No JSON object found in response")
    return json.loads(text[start : end + 1])


def _detect_mime_type(image_bytes: bytes) -> str:
    """Detect image MIME type from magic bytes."""
    if image_bytes[:8] == b'\x89PNG\r\n\x1a\n':
        return "image/png"
    if image_bytes[:2] == b'\xff\xd8':
        return "image/jpeg"
    if image_bytes[:6] in (b'GIF87a', b'GIF89a'):
        return "image/gif"
    if image_bytes[:4] == b'RIFF' and image_bytes[8:12] == b'WEBP':
        return "image/webp"
    # Default to JPEG for unknown formats
    return "image/jpeg"


def _analyze(payload: dict[str, Any]) -> dict[str, Any]:
    image_base64 = payload.get("image_base64")
    if not image_base64:
        raise ValueError("image_base64 is required")

    image_bytes = base64.b64decode(image_base64)
    if MAX_IMAGE_BYTES:
        max_bytes = int(MAX_IMAGE_BYTES)
        if len(image_bytes) > max_bytes:
            raise ValueError("image exceeds max size")

    image_hash = hashlib.sha256(image_bytes).hexdigest()
    cached = _analysis_cache.get(image_hash)
    if cached:
        return cached

    prompt = build_analyze_prompt(payload)
    client = _get_client()
    mime_type = _detect_mime_type(image_bytes)

    parts = [
        types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
        types.Part.from_text(text=prompt),
    ]
    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[types.Content(role="user", parts=parts)],
    )

    text = _extract_text(response)
    data = _extract_json(text)
    _analysis_cache.set(image_hash, data)
    return data


def _chat(payload: dict[str, Any]) -> dict[str, Any]:
    messages = payload.get("messages")
    if not isinstance(messages, list):
        raise ValueError("messages must be a list")

    context = payload.get("plant_context") or {}
    client = _get_client()

    # Debug logging
    print(f"DEBUG: Received {len(messages)} messages", flush=True)
    print(f"DEBUG: Plant context: {context}", flush=True)

    # Build multimodal conversation history
    contents = []
    system_prompt = build_chat_prompt([], context)  # Get system prompt without history

    # Prepend system message if we have messages
    if messages:
        contents.append(types.Content(
            role="user",
            parts=[types.Part.from_text(text=system_prompt)]
        ))
        contents.append(types.Content(
            role="model",
            parts=[types.Part.from_text(text="Understood. I'll provide plant care assistance with JSON responses.")]
        ))

    for i, msg in enumerate(messages):
        role = msg.get("role", "user").lower()
        # Gemini uses "model" instead of "assistant"
        if role == "assistant":
            role = "model"
        content_text = msg.get("content", "").strip()
        image_base64 = msg.get("image_base64")

        parts = []

        print(f"DEBUG: Message {i}: role={role}, has_text={bool(content_text)}, has_image={bool(image_base64)}", flush=True)

        # Add image if present
        if image_base64:
            try:
                image_bytes = base64.b64decode(image_base64)
                mime_type = _detect_mime_type(image_bytes)
                print(f"DEBUG: Image {i}: size={len(image_bytes)} bytes, mime={mime_type}", flush=True)
                parts.append(types.Part.from_bytes(data=image_bytes, mime_type=mime_type))
            except Exception as e:
                print(f"Warning: Failed to decode image in message {i}: {e}", flush=True)

        # Add text content
        if content_text:
            parts.append(types.Part.from_text(text=content_text))

        # Only add if we have parts
        if parts:
            print(f"DEBUG: Adding content with {len(parts)} parts (role={role})", flush=True)
            contents.append(types.Content(role=role, parts=parts))

    print(f"DEBUG: Total contents for Gemini: {len(contents)} (including system prompt)", flush=True)

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=contents,
    )

    text = _extract_text(response)
    return _extract_json(text)


def handle(request):
    path = request.path or "/"
    if request.method != "POST":
        return _json_response({"error": "method_not_allowed"}, 405)

    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return _error_response("invalid_json", "Request body must be JSON", 400)

    try:
        if path == "/analyze":
            data = _call_with_retry(lambda: _analyze(payload))
            return _json_response(data, 200)
        if path == "/chat":
            data = _call_with_retry(lambda: _chat(payload))
            return _json_response(data, 200)
        return _error_response("not_found", "Unknown endpoint", 404)
    except ValueError as exc:
        return _error_response("bad_request", str(exc), 400)
    except Exception as exc:
        print(f"ERROR: {type(exc).__name__}: {exc}", flush=True)
        import traceback
        traceback.print_exc()
        return _error_response("gemini_failed", "Gemini request failed. Please retry.", 502)
