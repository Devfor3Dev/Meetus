from pydantic import BaseModel, Field

from app.users.schemas import IdentityIn, UserOut

__all__ = [
    "AccessOut",
    "AuthOut",
    "CheckEmailIn",
    "CheckEmailOut",
    "FacebookLoginIn",
    "GoogleLoginIn",
    "IdentityIn",
    "LoginIn",
    "RegisterIn",
    "ResendIn",
]


class CheckEmailIn(BaseModel):
    email: str = Field(max_length=254)


class CheckEmailOut(BaseModel):
    exists: bool
    is_verified: bool


class RegisterIn(BaseModel):
    email: str = Field(max_length=254)
    first_name: str = Field(max_length=80)
    last_name: str = Field(max_length=80)
    password: str = Field(max_length=256)


class ResendIn(BaseModel):
    email: str = Field(max_length=254)


class LoginIn(BaseModel):
    email: str = Field(max_length=254)
    password: str = Field(max_length=256)


class GoogleLoginIn(BaseModel):
    id_token: str = Field(min_length=20, max_length=4096)


class FacebookLoginIn(BaseModel):
    access_token: str = Field(min_length=10, max_length=4096)


class AccessOut(BaseModel):
    access_token: str
    token_type: str = "Bearer"  # noqa: S105
    expires_in: int


class AuthOut(AccessOut):
    user: UserOut
