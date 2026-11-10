"""OpenAI Chat Completions provider."""

import httpx

from app.llm.base import LLMError, LLMProvider
from app.models import ChatTurn


class OpenAIProvider(LLMProvider):
    """Calls POST {base_url}/chat/completions."""

    name = "openai"

    def __init__(
        self,
        *,
        api_key: str,
        model: str,
        base_url: str = "https://api.openai.com/v1",
        client: httpx.Client | None = None,
        timeout: float = 30.0,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._base_url = base_url.rstrip("/")
        self._client = client or httpx.Client(timeout=timeout)
        self._owns_client = client is None

    def complete(self, messages: list[ChatTurn]) -> str:
        try:
            response = self._client.post(
                f"{self._base_url}/chat/completions",
                headers={
                    "authorization": f"Bearer {self._api_key}",
                    "content-type": "application/json",
                },
                json={
                    "model": self._model,
                    "messages": [
                        {"role": message.role, "content": message.content} for message in messages
                    ],
                    "max_tokens": 300,
                },
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise LLMError("OpenAI request failed") from exc

        try:
            payload = response.json()
            text = payload["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise LLMError("OpenAI returned an unexpected response") from exc

        if not isinstance(text, str) or not text.strip():
            raise LLMError("OpenAI returned an empty reply")
        return text.strip()

    def close(self) -> None:
        if self._owns_client:
            self._client.close()
