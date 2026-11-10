"""Anthropic Messages provider."""

import httpx

from app.llm.base import LLMError, LLMProvider
from app.models import ChatTurn


class AnthropicProvider(LLMProvider):
    """Calls POST {base_url}/v1/messages."""

    name = "anthropic"

    def __init__(
        self,
        *,
        api_key: str,
        model: str,
        base_url: str = "https://api.anthropic.com",
        client: httpx.Client | None = None,
        timeout: float = 30.0,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._base_url = base_url.rstrip("/")
        self._client = client or httpx.Client(timeout=timeout)
        self._owns_client = client is None

    def complete(self, messages: list[ChatTurn]) -> str:
        system_parts = [message.content for message in messages if message.role == "system"]
        dialogue = [message for message in messages if message.role != "system"]
        dialogue_payload = [
            {"role": message.role, "content": message.content} for message in dialogue
        ]
        body: dict[str, object] = {
            "model": self._model,
            "max_tokens": 300,
            "messages": dialogue_payload,
        }
        if system_parts:
            body["system"] = "\n\n".join(system_parts)

        try:
            response = self._client.post(
                f"{self._base_url}/v1/messages",
                headers={
                    "x-api-key": self._api_key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json=body,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise LLMError("Anthropic request failed") from exc

        try:
            payload = response.json()
            blocks = payload["content"]
            text = blocks[0]["text"]
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise LLMError("Anthropic returned an unexpected response") from exc

        if not isinstance(text, str) or not text.strip():
            raise LLMError("Anthropic returned an empty reply")
        return text.strip()

    def close(self) -> None:
        if self._owns_client:
            self._client.close()
