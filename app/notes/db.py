"""libpq reads PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD/PGSSL*.

Keep credentials out of URLs and exception responses.
"""
import psycopg
from psycopg.rows import dict_row


def connect():
    return psycopg.connect(connect_timeout=5, row_factory=dict_row)


def initialize():
    with connect() as connection:
        existed = connection.execute("SELECT to_regclass('notes') AS name").fetchone()["name"]
        connection.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                text TEXT NOT NULL CHECK (length(text) BETWEEN 1 AND 1000)
            )
        """)
        return existed is None


if __name__ == "__main__":
    print("Schema created" if initialize() else "Schema ready")
