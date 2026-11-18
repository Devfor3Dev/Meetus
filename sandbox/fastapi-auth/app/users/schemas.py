import re

from pydantic import BaseModel, ConfigDict, field_validator

# Lettres de toutes les langues, séparées par un espace, une apostrophe ou un trait d'union.
_NAME = re.compile(r"^[^\W\d_]+(?:[ '’-][^\W\d_]+)*$")


def clean_name(raw: str) -> str:
    name = " ".join(raw.split())
    if not 1 <= len(name) <= 50 or not _NAME.match(name):
        raise ValueError("invalid_name")
    return name


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    first_name: str | None
    last_name: str | None
    is_verified: bool
    needs_identity: bool


class IdentityIn(BaseModel):
    first_name: str
    last_name: str

    @field_validator("first_name", "last_name")
    @classmethod
    def _valid(cls, value: str) -> str:
        return clean_name(value)
