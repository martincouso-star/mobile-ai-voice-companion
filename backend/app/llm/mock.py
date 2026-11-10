"""Deterministic companion used when no model API key is configured."""

import re

from app.llm.base import LLMProvider
from app.models import ChatTurn


class MockLLM(LLMProvider):
    """Same transcript always produces the same reply.

    The wording changes when earlier user turns are present, so tests and
    the app can see that session memory was sent to the provider.
    """

    name = "mock"

    def complete(self, messages: list[ChatTurn]) -> str:
        user_turns = [turn.content.strip() for turn in messages if turn.role == "user"]
        user_turns = [text for text in user_turns if text]
        if not user_turns:
            return "I'm here. Say something when you're ready."

        last = user_turns[-1]
        prior = user_turns[:-1]
        lowered = last.lower()

        if re.search(r"\b(hi|hello|hey)\b", lowered):
            reply = "Hello. I'm here with you."
        elif "who are you" in lowered or "your name" in lowered:
            reply = "I'm your voice companion. I listen, and I talk things through with you."
        elif re.search(r"\bwhat did i (say|tell you)\b", lowered) or lowered.startswith("remember"):
            if prior:
                reply = f"You mentioned: {prior[-1]}"
            else:
                reply = "This session just started, so there is nothing earlier to recall."
        elif "help" in lowered:
            reply = (
                "Hold the microphone button and talk, or type a message. "
                "I will answer, and the phone can read that answer aloud."
            )
        else:
            reply = f"I heard you say: {last}"

        if prior and not re.search(r"\bwhat did i (say|tell you)\b", lowered):
            notes = "note" if len(prior) == 1 else "notes"
            reply += f" I still have {len(prior)} earlier {notes} from this session."
        return reply
