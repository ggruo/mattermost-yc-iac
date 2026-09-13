from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import psycopg

from notes import db

app = FastAPI(title="Cloud Notes")


class NewNote(BaseModel):
    text: str = Field(min_length=1, max_length=1000)


def unavailable():
    return HTTPException(status_code=503, detail="Database unavailable")


@app.get("/healthz")
def health():
    # Liveness must not depend on PostgreSQL.
    return {"status": "ok"}


@app.get("/readyz")
def ready():
    try:
        with db.connect() as connection:
            connection.execute("SELECT 1 FROM notes LIMIT 1")
        return {"status": "ready"}
    except psycopg.Error:
        raise unavailable() from None


@app.get("/notes")
def list_notes():
    try:
        with db.connect() as connection:
            return connection.execute("SELECT id, text FROM notes ORDER BY id DESC LIMIT 100").fetchall()
    except psycopg.Error:
        raise unavailable() from None


@app.post("/notes", status_code=201)
def create_note(note: NewNote):
    try:
        with db.connect() as connection:
            return connection.execute(
                "INSERT INTO notes (text) VALUES (%s) RETURNING id, text", (note.text,)
            ).fetchone()
    except psycopg.Error:
        raise unavailable() from None
