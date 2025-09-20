"""Load data to local Parquet (fast) or to S3 if AWS creds provided."""
import os
from pathlib import Path
import pandas as pd
import psycopg2

from .config import OUTPUT_DIR, POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, POSTGRES_PORT

DB_CONN_STRING = (
    f"dbname={POSTGRES_DB} user={POSTGRES_USER} password={POSTGRES_PASSWORD} "
    f"host={POSTGRES_HOST} port={POSTGRES_PORT}"
)

def save_parquet(records: list, filename: str = None):
    Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
    df = pd.DataFrame(records)
    filename = filename or f"quotes_{pd.Timestamp.utcnow().strftime('%Y%m%d%H%M%S')}.parquet"
    out = Path(OUTPUT_DIR) / filename
    df.to_parquet(out, index=False)
    return str(out)

def save_postgres(records: list):
    conn = psycopg2.connect(DB_CONN_STRING)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS quotes (
            symbol TEXT,
            open NUMERIC,
            high NUMERIC,
            low NUMERIC,
            close NUMERIC,
            volume BIGINT,
            timestamp DATE
        )
    """)
    for r in records:
        cur.execute(
            "INSERT INTO quotes VALUES (%s,%s,%s,%s,%s,%s,%s)",
            (r["symbol"], r["open"], r["high"], r["low"],
             r["close"], r["volume"], r["timestamp"])
        )
    conn.commit()
    cur.close()
    conn.close()