"""Settings validation."""

import pytest
from pydantic import ValidationError

from app.config import Settings


def test_history_cap_rejects_values_outside_the_supported_range() -> None:
    with pytest.raises(ValidationError):
        Settings(_env_file=None, max_history_turns=1)
    with pytest.raises(ValidationError):
        Settings(_env_file=None, max_history_turns=201)
    assert Settings(_env_file=None, max_history_turns=2).max_history_turns == 2
