"""Provider interface."""

from abc import ABC, abstractmethod

from app.models import ChatTurn


class LLMError(Exception):
    """The provider was called and failed."""


class LLMConfigError(Exception):
    """The process is not configured to build the selected provider."""


class LLMProvider(ABC):
    """Turns a prompt transcript into one assistant reply."""

    name: str

    @abstractmethod
    def complete(self, messages: list[ChatTurn]) -> str:
        """Return the assistant text for this transcript."""
