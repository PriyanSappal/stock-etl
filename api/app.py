from fastapi import FastAPI, HTTPException
import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables from .env (only needed locally)
load_dotenv()

app = FastAPI()

DB_CONN = {
    "dbname": os.getenv("POSTGRES_DB"),
    "user": os.getenv("POSTGRES_USER"),
    "password": os.getenv("POSTGRES_PASSWORD"),
    "host": os.getenv("POSTGRES_HOST"),
    "port": os.getenv("POSTGRES_PORT"),
}


def get_connection():
    return psycopg2.connect(**DB_CONN)


@app.get("/quote")
def get_quote(symbol: str = "ASX"):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT symbol, open, high, low, close, volume, timestamp
        FROM quotes
        WHERE symbol = %s
        ORDER BY timestamp DESC
        LIMIT 5;
        """,
        (symbol,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    if not rows:
        raise HTTPException(status_code=404, detail="Symbol not found")

    return [
        {
            "symbol": r[0],
            "open": float(r[1]) if r[1] is not None else None,
            "high": float(r[2]) if r[2] is not None else None,
            "low": float(r[3]) if r[3] is not None else None,
            "close": float(r[4]) if r[4] is not None else None,
            "volume": int(r[5]) if r[5] is not None else None,
            "timestamp": r[6].isoformat(),
        }
        for r in rows
    ]
