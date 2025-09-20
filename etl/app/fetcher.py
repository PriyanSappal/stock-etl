"""Fetch financial data from Alpha Vantage API."""
import requests
from .config import ALPHAVANTAGE_API_KEY

class AlphaVantageFetcher:
    BASE = "https://www.alphavantage.co/query"

    def __init__(self, api_key=None):
        self.api_key = api_key or ALPHAVANTAGE_API_KEY

    def daily_series(self, symbol: str, output_size="compact"):
        """Fetch daily OHLCV time series for a stock symbol."""
        params = {
            "function": "TIME_SERIES_DAILY",
            "symbol": symbol,
            "outputsize": output_size,
            "apikey": self.api_key,
        }
        r = requests.get(self.BASE, params=params, timeout=10)
        r.raise_for_status()
        return r.json()  # Keep full JSON for transformer
        

def get_fetcher(provider_name: str):
    if provider_name == "alphavantage":
        return AlphaVantageFetcher()
    raise ValueError("Unsupported provider")
