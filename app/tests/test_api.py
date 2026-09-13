import os
from unittest.mock import MagicMock

import psycopg
import pytest
from fastapi.testclient import TestClient
from notes import db
from notes.main import app

client = TestClient(app)


def test_database_failure_keeps_liveness_and_hides_secret(monkeypatch):
    def fail():
        raise psycopg.OperationalError("password=never-return-this")
    monkeypatch.setattr(db, "connect", fail)
    assert client.get("/healthz").status_code == 200
    for response in (client.get("/readyz"), client.get("/notes"), client.post("/notes", json={"text": "test"})):
        assert response.status_code == 503
        assert "never-return-this" not in response.text


def test_readiness_and_parameterized_insert(monkeypatch):
    connection = MagicMock()
    connection.__enter__.return_value = connection
    connection.execute.return_value.fetchone.return_value = {"id": 1, "text": "'quoted'"}
    connection.execute.return_value.fetchall.return_value = [{"id": 1, "text": "'quoted'"}]
    monkeypatch.setattr(db, "connect", lambda: connection)
    assert client.get("/readyz").status_code == 200
    response = client.post("/notes", json={"text": "'quoted'"})
    assert response.status_code == 201
    assert connection.execute.call_args.args[1] == ("'quoted'",)
    assert client.get("/notes").json() == [response.json()]


@pytest.mark.parametrize("text", ["", "x" * 1001])
def test_invalid_note(text):
    assert client.post("/notes", json={"text": text}).status_code == 422


@pytest.mark.skipif(os.environ.get("RUN_DB_TESTS") != "1", reason="requires an isolated PostgreSQL database")
def test_real_postgresql_persistence():
    db.initialize()
    db.initialize()
    response = client.post("/notes", json={"text": "integration-note"})
    assert response.status_code == 201
    note = response.json()
    try:
        # A separate connection is opened by the GET request.
        assert note in client.get("/notes").json()
        assert client.get("/readyz").status_code == 200
    finally:
        with db.connect() as connection:
            connection.execute("DELETE FROM notes WHERE id = %s", (note["id"],))
