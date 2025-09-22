"""Transform Alpha Vantage TIME_SERIES_DAILY output into normalised records."""
from datetime import datetime


def daily_series_to_records(symbol: str, series_json: dict):
    """
    Convert Alpha Vantage TIME_SERIES_DAILY into a list of records.
    Each record has symbol, open, high, low, close, volume, timestamp.
    """
    time_series = series_json.get("Time Series (Daily)", {})
    records = []

    for date_str, values in time_series.items():
        records.append({
            "symbol": symbol,
            "open": _to_float(values.get("1. open")),
            "high": _to_float(values.get("2. high")),
            "low": _to_float(values.get("3. low")),
            "close": _to_float(values.get("4. close")),
            "volume": _to_int(values.get("5. volume")),
            "timestamp": _parse_date(date_str),
        })

    return records


def _to_float(val):
    try:
        return float(val)
    except (TypeError, ValueError):
        return None


def _to_int(val):
    try:
        return int(val)
    except (TypeError, ValueError):
        return None


def _parse_date(val):
    try:
        return datetime.strptime(val, "%Y-%m-%d")
    except (TypeError, ValueError):
        return None