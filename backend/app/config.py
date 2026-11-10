"""Runtime settings loaded from the environment."""

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration for the API process.

    The mock provider is the default so a checkout runs without API keys.
    """

    llm_provider: str = "mock"
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_base_url: str = "https://api.openai.com/v1"
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-3-5-haiku-latest"
    anthropic_base_url: str = "https://api.anthropic.com"
    max_history_turns: int = 20
    cors_origins: str = "*"

    @field_validator("max_history_turns")
    @classmethod
    def history_cap(cls, value: int) -> int:
        if value < 2 or value > 200:
            raise ValueError("MAX_HISTORY_TURNS must be between 2 and 200")
        return value

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )
