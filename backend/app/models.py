"""Request and response models shared by the API and the LLM layer."""

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class ChatTurn(BaseModel):
    """One message in a conversation."""

    role: Literal["system", "user", "assistant"]
    content: str


class ChatRequest(BaseModel):
    """Body of POST /chat."""

    message: str = Field(min_length=1, max_length=8000)
    session_id: str | None = None

    @field_validator("message")
    @classmethod
    def message_not_blank(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("message must not be empty")
        return stripped

    @field_validator("session_id")
    @classmethod
    def session_id_ok(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        if not stripped or len(stripped) > 128:
            raise ValueError("session_id is invalid")
        return stripped


class ChatResponse(BaseModel):
    """Reply returned to the mobile client."""

    session_id: str
    reply: str
    provider: str
