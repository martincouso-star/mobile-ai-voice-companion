"""Select a provider from settings."""

import httpx

from app.config import Settings
from app.llm.anthropic import AnthropicProvider
from app.llm.base import LLMConfigError, LLMProvider
from app.llm.mock import MockLLM
from app.llm.openai import OpenAIProvider


def build_llm(settings: Settings, client: httpx.Client | None = None) -> LLMProvider:
    """Return the provider named by LLM_PROVIDER.

    ``client`` is for tests. Production builds its own HTTP client inside
    the provider.
    """

    provider = settings.llm_provider.strip().lower()
    if provider == "mock":
        return MockLLM()
    if provider == "openai":
        if not settings.openai_api_key.strip():
            raise LLMConfigError("OPENAI_API_KEY is required when LLM_PROVIDER=openai")
        return OpenAIProvider(
            api_key=settings.openai_api_key,
            model=settings.openai_model,
            base_url=settings.openai_base_url,
            client=client,
        )
    if provider == "anthropic":
        if not settings.anthropic_api_key.strip():
            raise LLMConfigError("ANTHROPIC_API_KEY is required when LLM_PROVIDER=anthropic")
        return AnthropicProvider(
            api_key=settings.anthropic_api_key,
            model=settings.anthropic_model,
            base_url=settings.anthropic_base_url,
            client=client,
        )
    raise LLMConfigError(
        f"Unknown LLM_PROVIDER '{settings.llm_provider}'. Use mock, openai, or anthropic."
    )
