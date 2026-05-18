"""
Configuracion compartida de pytest.

Sustituye Postgres por SQLite en memoria para no depender del contenedor de BD.
"""
import os
from collections.abc import Iterator

os.environ["DATABASE_URL"] = "sqlite+pysqlite:///:memory:"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app import database  # noqa: E402
from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402

_TEST_ENGINE = create_engine(
    "sqlite+pysqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
    future=True,
)
_TestSession = sessionmaker(bind=_TEST_ENGINE, autoflush=False, autocommit=False, future=True)

Base.metadata.create_all(bind=_TEST_ENGINE)
database.engine = _TEST_ENGINE
database.SessionLocal = _TestSession


def _override_get_db() -> Iterator:
    db = _TestSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture()
def client() -> Iterator[TestClient]:
    with _TEST_ENGINE.begin() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            conn.execute(table.delete())
    yield TestClient(app)
