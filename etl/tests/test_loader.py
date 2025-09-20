import os
import pandas as pd
import pytest
from pathlib import Path
from app.loader import save_parquet

def test_save_parquet(tmp_path):
    records = [{
        "symbol": "ASX",
        "open": 165.0,
        "high": 170.0,
        "low": 164.0,
        "close": 168.0,
        "volume": 12000,
        "timestamp": pd.Timestamp("2025-09-18"),
    }]
    out_file = save_parquet(records, filename="test.parquet")
    assert Path(out_file).exists()

    df = pd.read_parquet(out_file)
    assert df.iloc[0]["symbol"] == "ASX"

# Optional: Postgres mock test
import psycopg2

def test_save_postgres(monkeypatch):
    calls = []
    class DummyCursor:
        def execute(self, query, params=None): calls.append((query, params))
        def close(self): pass
    class DummyConn:
        def cursor(self): return DummyCursor()
        def commit(self): pass
        def close(self): pass

    monkeypatch.setattr(psycopg2, "connect", lambda _: DummyConn())

    from app.loader import save_postgres
    records = [{"symbol": "ASX", "open": 1, "high": 2, "low": 0.5, "close": 1.5, "volume": 100, "timestamp": "2025-09-18"}]
    save_postgres(records)
    assert any("INSERT INTO quotes" in c[0] for c in calls)
