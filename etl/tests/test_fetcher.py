import pytest
import requests
from app.fetcher import AlphaVantageFetcher

class DummyResponse:
    def __init__(self, json_data, status=200):
        self._json = json_data
        self.status_code = status
    def json(self): return self._json
    def raise_for_status(self): 
        if self.status_code != 200:
            raise requests.HTTPError("Bad response")

def test_daily_series_fetch(monkeypatch):
    sample_json = {
        "Time Series (Daily)": {
            "2025-09-18": {
                "1. open": "165.0",
                "2. high": "170.0",
                "3. low": "164.0",
                "4. close": "168.0",
                "5. volume": "12000",
            }
        }
    }

    def fake_get(url, params, timeout):
        return DummyResponse(sample_json)

    monkeypatch.setattr(requests, "get", fake_get)

    fetcher = AlphaVantageFetcher(api_key="DUMMY")
    data = fetcher.daily_series("MQG.AX")
    assert "Time Series (Daily)" in data
    assert list(data["Time Series (Daily)"].keys()) == ["2025-09-18"]
