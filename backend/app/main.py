"""FastAPI application."""

import logging
from typing import Annotated
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware

from app.config import Settings
from app.llm import LLMError, build_llm
from app.llm.base import LLMProvider
from app.llm.prompts import SYSTEM_PROMPT
from app.memory import SessionMemory
from app.models import ChatRequest, ChatResponse, ChatTurn

logger = logging.getLogger(__name__)


def _configure_logging() -> None:
    if logging.getLogger().handlers:
        return
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")


def get_memory(request: Request) -> SessionMemory:
    return request.app.state.memory


def get_llm(request: Request) -> LLMProvider:
    return request.app.state.llm


MemoryDep = Annotated[SessionMemory, Depends(get_memory)]
LLMDep = Annotated[LLMProvider, Depends(get_llm)]


def create_app(settings: Settings | None = None) -> FastAPI:
    """Build the API. Tests pass an explicit Settings object."""

    _configure_logging()
    settings = settings or Settings()
    memory = SessionMemory(max_turns=settings.max_history_turns)
    llm = build_llm(settings)

    app = FastAPI(
        title="Voice Companion API",
        version="0.1.0",
        summary="Session chat for the Mobile AI Voice Companion.",
    )
    app.state.settings = settings
    app.state.memory = memory
    app.state.llm = llm

    origins = [item.strip() for item in settings.cors_origins.split(",") if item.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins or ["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/")
    def root() -> dict[str, str]:
        return {
            "service": "voice-companion",
            "health": "/health",
            "chat": "/chat",
        }

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok", "provider": llm.name}

    @app.post("/chat", response_model=ChatResponse)
    def chat(body: ChatRequest, store: MemoryDep, provider: LLMDep) -> ChatResponse:
        session_id = body.session_id or str(uuid4())
        history = store.get(session_id)
        user_turn = ChatTurn(role="user", content=body.message)
        transcript = [ChatTurn(role="system", content=SYSTEM_PROMPT), *history, user_turn]
        try:
            reply = provider.complete(transcript).strip()
        except LLMError as exc:
            logger.warning("llm failure session=%s provider=%s", session_id, provider.name)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="The companion could not produce a reply.",
            ) from exc
        if not reply:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="The companion returned an empty reply.",
            )
        store.append(session_id, user_turn)
        store.append(session_id, ChatTurn(role="assistant", content=reply))
        logger.info(
            "chat session=%s provider=%s stored_turns=%s",
            session_id,
            provider.name,
            len(history) + 2,
        )
        return ChatResponse(session_id=session_id, reply=reply, provider=provider.name)

    @app.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
    def delete_session(session_id: str, store: MemoryDep) -> None:
        if not session_id.strip() or len(session_id) > 128:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="session_id is invalid",
            )
        store.delete(session_id)

    return app


app = create_app()
