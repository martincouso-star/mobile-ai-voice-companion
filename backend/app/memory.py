"""In-process conversation memory keyed by session id.

Cloud Run can run more than one instance, and instances are replaced.
This store lives only in the process that handled the request. See the
repository README for that limitation.
"""

import threading

from app.models import ChatTurn


class SessionMemory:
    """Thread-safe list of turns for each session."""

    def __init__(self, max_turns: int = 20) -> None:
        if max_turns < 2:
            raise ValueError("max_turns must keep at least one exchange")
        self._max_turns = max_turns
        self._sessions: dict[str, list[ChatTurn]] = {}
        self._lock = threading.Lock()

    def get(self, session_id: str) -> list[ChatTurn]:
        with self._lock:
            return list(self._sessions.get(session_id, []))

    def append(self, session_id: str, turn: ChatTurn) -> None:
        with self._lock:
            history = self._sessions.setdefault(session_id, [])
            history.append(turn)
            overflow = len(history) - self._max_turns
            if overflow > 0:
                # Keep user/assistant pairs when the cap would split one.
                if overflow % 2 == 1:
                    overflow += 1
                del history[: min(overflow, len(history))]

    def delete(self, session_id: str) -> bool:
        with self._lock:
            return self._sessions.pop(session_id, None) is not None

    def __len__(self) -> int:
        with self._lock:
            return len(self._sessions)
