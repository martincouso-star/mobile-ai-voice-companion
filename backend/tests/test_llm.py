"""Provider selection and HTTP provider request shapes."""

import json

import httpx
import pytest

from app.config import Settings
from app.llm.base import LLMConfigError
from app.llm.factory import build_llm
from app.llm.mock import MockLLM
from app.models import ChatTurn


def _settings(**overrides: str) -> Settings:
    return Settings(_env_file=None, **overrides)


def test_default_provider_is_mock() -> None:
    provider = build_llm(_settings())
    assert isinstance(provider, MockLLM)
    assert provider.name == "mock"


def test_mock_is_deterministic_and_uses_history() -> None:
    provider = MockLLM()
    first = [
        ChatTurn(role="system", content="be brief"),
        ChatTurn(role="user", content="Hello there"),
    ]
    second = [
        *first,
        ChatTurn(role="assistant", content="Hello. I'm here with you."),
        ChatTurn(role="user", content="What did I say?"),
    ]
    assert provider.complete(first) == provider.complete(list(first))
    assert provider.complete(second) == "You mentioned: Hello there"


def test_unknown_provider_is_rejected() -> None:
    with pytest.raises(LLMConfigError):
        build_llm(_settings(llm_provider="local-llama"))


def test_openai_requires_a_key() -> None:
    with pytest.raises(LLMConfigError):
        build_llm(_settings(llm_provider="openai", openai_api_key=""))


def test_anthropic_requires_a_key() -> None:
    with pytest.raises(LLMConfigError):
        build_llm(_settings(llm_provider="anthropic", anthropic_api_key="  "))


def test_openai_provider_posts_chat_completions() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["auth"] = request.headers["authorization"]
        seen["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            json={"choices": [{"message": {"content": "  A short reply.  "}}]},
        )

    provider = build_llm(
        _settings(llm_provider="openai", openai_api_key="test-key", openai_model="gpt-test"),
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )
    reply = provider.complete(
        [
            ChatTurn(role="system", content="be brief"),
            ChatTurn(role="user", content="hi"),
        ]
    )
    assert reply == "A short reply."
    assert seen["url"] == "https://api.openai.com/v1/chat/completions"
    assert seen["auth"] == "Bearer test-key"
    assert seen["body"] == {
        "model": "gpt-test",
        "messages": [
            {"role": "system", "content": "be brief"},
            {"role": "user", "content": "hi"},
        ],
        "max_tokens": 300,
    }


def test_openai_provider_reports_http_errors() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(500, json={"error": "nope"})

    provider = build_llm(
        _settings(llm_provider="openai", openai_api_key="test-key"),
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )
    from app.llm.base import LLMError

    with pytest.raises(LLMError):
        provider.complete([ChatTurn(role="user", content="hi")])


def test_anthropic_provider_posts_messages() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["key"] = request.headers["x-api-key"]
        seen["version"] = request.headers["anthropic-version"]
        seen["body"] = json.loads(request.content)
        return httpx.Response(200, json={"content": [{"type": "text", "text": "Hello back."}]})

    provider = build_llm(
        _settings(
            llm_provider="anthropic",
            anthropic_api_key="anthropic-test",
            anthropic_model="claude-test",
        ),
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )
    reply = provider.complete(
        [
            ChatTurn(role="system", content="be brief"),
            ChatTurn(role="user", content="hi"),
            ChatTurn(role="assistant", content="hello"),
            ChatTurn(role="user", content="again"),
        ]
    )
    assert reply == "Hello back."
    assert seen["url"] == "https://api.anthropic.com/v1/messages"
    assert seen["key"] == "anthropic-test"
    assert seen["version"] == "2023-06-01"
    assert seen["body"]["system"] == "be brief"
    assert seen["body"]["messages"] == [
        {"role": "user", "content": "hi"},
        {"role": "assistant", "content": "hello"},
        {"role": "user", "content": "again"},
    ]
    assert seen["body"]["model"] == "claude-test"


def test_anthropic_provider_rejects_an_empty_reply() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"content": [{"text": "   "}]})

    provider = build_llm(
        _settings(llm_provider="anthropic", anthropic_api_key="k"),
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )
    from app.llm.base import LLMError

    with pytest.raises(LLMError):
        provider.complete([ChatTurn(role="user", content="hi")])
