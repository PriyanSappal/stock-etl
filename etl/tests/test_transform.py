from app.transform import daily_series_to_records

def test_daily_series_to_records():
    raw = {
        "Time Series (Daily)": {
            "2025-09-17": {
                "1. open": "11.3800",
                "2. high": "11.3950",
                "3. low": "11.1650",
                "4. close": "11.3000",
                "5. volume": "5604829",
            }
        }
    }
    recs = daily_series_to_records("ASX", raw)
    r = recs[0]

    assert r["symbol"] == "ASX"
    assert r["open"] == 11.38
    assert r["close"] == 11.3
    assert r["volume"] == 5604829
    assert str(r["timestamp"]).startswith("2025-09-17")
