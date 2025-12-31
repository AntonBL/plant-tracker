from __future__ import annotations

from typing import Any


def build_analyze_prompt(context: dict[str, Any]) -> str:
    plant_name = context.get("plant_name") or "Unknown"
    species = context.get("species") or "Unknown"
    season = context.get("season") or "Unknown"
    last_watered = context.get("last_watered") or "Unknown"
    current_date = context.get("current_date") or "Unknown"
    custom_prompt = context.get("custom_prompt")

    base_prompt = (
        "You are a plant health assistant. Analyze the plant photo and return JSON only. "
        "Do not include extra text or markdown.\n\n"
        "Return a JSON object with exactly these keys:\n"
        "status (one of: healthy, needs_attention, critical),\n"
        "confidence (0.0 to 1.0),\n"
        "issues (array of strings),\n"
        "recommendations (array of strings),\n"
        "suggested_interval_days (number),\n"
        "rationale (string),\n"
        "suggested_name (string, optional - provide if plant_name is Unknown).\n\n"
        "Context:\n"
        f"- plant_name: {plant_name}\n"
        f"- species: {species}\n"
        f"- season: {season}\n"
        f"- current_date: {current_date}\n"
        f"- last_watered: {last_watered}\n"
    )

    # Add note about name suggestion if plant_name is Unknown
    if plant_name == "Unknown":
        base_prompt += (
            "\nNOTE: The user has not provided a name for this plant. "
            "Please analyze the image and suggest an appropriate name in the 'suggested_name' field. "
            "This could be the common name or scientific name based on what you can identify.\n"
        )

    # Append custom prompt if provided
    if custom_prompt:
        base_prompt += f"\nUser's specific question/concern: {custom_prompt}\n"
        base_prompt += "Please address this question in your analysis.\n"

    base_prompt += "\nIf information is uncertain, state that in the rationale."

    return base_prompt


def build_chat_prompt(
    messages: list[dict[str, str]],
    context: dict[str, Any],
) -> str:
    plant_name = context.get("plant_name") or "Unknown"
    species = context.get("species") or "Unknown"
    status = context.get("last_assessment_status") or "Unknown"
    current_date = context.get("current_date") or "Unknown"

    # Build system prompt (without conversation history for multimodal)
    system_prompt = (
        "You are a plant care assistant. Respond to the user and return JSON only. "
        "Do not include extra text or markdown.\n\n"
        "Return a JSON object with exactly these keys:\n"
        "reply (string),\n"
        "action_suggestions (array of strings),\n"
        "safety_note (string, optional).\n\n"
        "Plant context:\n"
        f"- plant_name: {plant_name}\n"
        f"- species: {species}\n"
        f"- current_date: {current_date}\n"
        f"- last_assessment_status: {status}\n\n"
        "If the user has attached an image, analyze it in your response. "
        "Reference images in the conversation history when relevant (e.g., 'Based on the photo you shared earlier...')."
    )

    # For backward compatibility, if messages are provided, build old-style prompt
    if messages:
        history_lines = []
        for msg in messages:
            role = msg.get("role", "user").strip().lower()
            content = msg.get("content", "").strip()
            has_image = bool(msg.get("image_base64"))
            if content:
                image_note = " [with image]" if has_image else ""
                history_lines.append(f"{role}: {content}{image_note}")

        history = "\n".join(history_lines) if history_lines else "user: (no messages)"
        return f"{system_prompt}\n\nConversation:\n{history}\n"

    return system_prompt
