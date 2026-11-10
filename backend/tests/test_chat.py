"""HTTP tests for session chat."""

from fastapi.testclient import TestClient

from app.config import Settings
from app.llm.base import LLMError, LLMProvider
from app.llm.prompts import SYSTEM_PROMPT
from app.main import create_app
from app.models import ChatTurn


def test_health(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "provider": "mock"}


def test_root_lists_routes(client: TestClient) -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["chat"] == "/chat"


def test_chat_creates_a_session_and_remembers_it(client: TestClient) -> None:
    first = client.post("/chat", json={"message": "Hello"})
    assert first.status_code == 200
    body = first.json()
    assert body["provider"] == "mock"
    assert body["reply"] == "Hello. I'm here with you."
    session_id = body["session_id"]
    assert session_id

    second = client.post(
        "/chat",
        json={"session_id": session_id, "message": "What did I say?"},
    )
    assert second.status_code == 200
    assert second.json()["session_id"] == session_id
    assert second.json()["reply"] == "You mentioned: Hello"


def test_sessions_do_not_share_memory(client: TestClient) -> None:
    one = client.post("/chat", json={"session_id": "session-one", "message": "Hello"})
    two = client.post("/chat", json={"session_id": "session-two", "message": "What did I say?"})
    assert one.status_code == 200
    assert two.json()["reply"] == (
        "This session just started, so there is nothing earlier to recall."
    )


def test_blank_message_is_rejected(client: TestClient) -> None:
    response = client.post("/chat", json={"message": "   "})
    assert response.status_code == 422


def test_delete_session_forgets_history(client: TestClient) -> None:
    created = client.post("/chat", json={"session_id": "forget-me", "message": "Hello"})
    assert created.status_code == 200
    deleted = client.delete("/sessions/forget-me")
    assert deleted.status_code == 204
    again = client.post("/chat", json={"session_id": "forget-me", "message": "What did I say?"})
    assert "nothing earlier" in again.json()["reply"]


def test_delete_missing_session_is_idempotent(client: TestClient) -> None:
    assert client.delete("/sessions/never-existed").status_code == 204


def test_provider_failure_is_a_bad_gateway() -> None:
    class Boom(LLMProvider):
        name = "boom"

        def complete(self, messages: list[ChatTurn]) -> str:
            raise LLMError("down")

    app = create_app(Settings(_env_file=None, llm_provider="mock"))
    app.state.llm = Boom()
    with TestClient(app) as client:
        response = client.post("/chat", json={"message": "Hello"})
    assert response.status_code == 502
    assert response.json()["detail"] == "The companion could not produce a reply."


def test_transcript_includes_the_system_prompt_and_history() -> None:
    class Recorder(LLMProvider):
        name = "recorder"

        def __init__(self) -> None:
            self.calls: list[list[ChatTurn]] = []

        def complete(self, messages: list[ChatTurn]) -> str:
            self.calls.append(messages)
            return "Noted."

    recorder = Recorder()
    app = create_app(Settings(_env_file=None, llm_provider="mock"))
    app.state.llm = recorder
    with TestClient(app) as client:
        assert client.post("/chat", json={"session_id": "s", "message": "First"}).status_code == 200
        second_response = client.post("/chat", json={"session_id": "s", "message": "Second"})
    assert second_response.status_code == 200

    second = recorder.calls[1]
    assert second[0] == ChatTurn(role="system", content=SYSTEM_PROMPT)
    assert [turn.content for turn in second[1:]] == ["First", "Noted.", "Second"]
