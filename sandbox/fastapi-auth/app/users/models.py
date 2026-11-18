import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email: Mapped[str] = mapped_column(String(254), unique=True)
    first_name: Mapped[str | None] = mapped_column(String(50), default=None)
    last_name: Mapped[str | None] = mapped_column(String(50), default=None)
    # Vide pour un compte créé uniquement via Google ou Facebook.
    password_hash: Mapped[str | None] = mapped_column(String(255), default=None)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    failed_logins: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    @property
    def needs_identity(self) -> bool:
        return not (self.first_name and self.last_name)
