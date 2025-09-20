from app import etl

def test_etl_run(monkeypatch):
    class DummyFetcher:
        def daily_series(self, symbol, output_size="compact"):
            return {
                "Time Series (Daily)": {
                    "2021-01-01": {
                        "1. open": "100",
                        "2. high": "110",
                        "3. low": "90",
                        "4. close": "105",
                        "5. volume": "1000",
                    }
                }
            }

    # Patch fetcher to use dummy instead of real API
    monkeypatch.setattr(etl, "get_fetcher", lambda provider: DummyFetcher())

    # Patch loaders to avoid real writes
    monkeypatch.setattr(etl, "save_parquet", lambda recs: "dummy.parquet")
    monkeypatch.setattr(etl, "save_postgres", lambda recs: None)

    # Run should succeed with dummy data
    etl.run()
