"""Session memory unit tests."""

import threading

from app.memory import SessionMemory
from app.models import ChatTurn


def test_sessions_are_isolated() -> None:
    memory = SessionMemory(max_turns=10)
    memory.append("a", ChatTurn(role="user", content="one"))
    memory.append("b", ChatTurn(role="user", content="two"))
    assert [turn.content for turn in memory.get("a")] == ["one"]
    assert [turn.content for turn in memory.get("b")] == ["two"]
    assert memory.get("missing") == []


def test_trims_oldest_pairs() -> None:
    memory = SessionMemory(max_turns=4)
    for index in range(3):
        memory.append("s", ChatTurn(role="user", content=f"u{index}"))
        memory.append("s", ChatTurn(role="assistant", content=f"a{index}"))
    contents = [turn.content for turn in memory.get("s")]
    assert contents == ["u1", "a1", "u2", "a2"]


def test_delete_removes_session() -> None:
    memory = SessionMemory()
    memory.append("s", ChatTurn(role="user", content="hi"))
    assert memory.delete("s") is True
    assert memory.delete("s") is False
    assert memory.get("s") == []


def test_appends_are_safe_across_threads() -> None:
    memory = SessionMemory(max_turns=500)
    errors: list[BaseException] = []

    def worker(start: int) -> None:
        try:
            for offset in range(50):
                memory.append("s", ChatTurn(role="user", content=f"{start}-{offset}"))
        except BaseException as exc:  # pragma: no cover - failure path
            errors.append(exc)

    threads = [threading.Thread(target=worker, args=(index,)) for index in range(8)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    assert errors == []
    assert len(memory.get("s")) == 400
