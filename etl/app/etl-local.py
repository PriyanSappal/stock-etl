"""Main ETL runner. Extract (Fetch) -> Transform -> Load"""
import logging
import os
from .fetcher import get_fetcher, AlphaVantageFetcher
from .transform import daily_series_to_records
from .loader import save_parquet, save_postgres
from .config import SYMBOL, PROVIDER
from .s3upload import upload_to_s3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("stock_etl")


def run():
    logger.info("Starting ETL")
    fetcher = get_fetcher(PROVIDER)

    for symbol in SYMBOL:
        symbol = symbol.strip().upper()
        logger.info("Processing symbol: %s", symbol)

        raw = fetcher.daily_series(symbol)  
        logger.info("Raw API response for %s: %s", symbol, raw)
        records = daily_series_to_records(symbol, raw)

        out_path = save_parquet(records, filename=f"{symbol}_quotes.parquet")
        logger.info("Saved %s data to %s", symbol, out_path)

        try:
            save_postgres(records)
            logger.info("Inserted %s records into Postgres", symbol)
        except Exception as e:
            logger.warning("Postgres save failed for %s: %s", symbol, e)



if __name__ == "__main__":
    run()
