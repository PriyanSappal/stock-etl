"""ETL runner that loads existing parquet into Postgres without API calls."""

import logging
import glob
import pandas as pd
from .loader import save_postgres

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("stock_etl_parquet")


def run():
    logger.info("Starting ETL (from parquet only)")

    parquet_files = glob.glob("app/data/*.parquet")
    if not parquet_files:
        logger.error("No parquet files found in app/data/")
        return

    for fpath in parquet_files:
        logger.info("Loading parquet file: %s", fpath)
        df = pd.read_parquet(fpath)

        try:
            save_postgres(df.to_dict(orient="records"))
            logger.info("Inserted %s records into Postgres from %s", len(df), fpath)
        except Exception as e:
            logger.warning("Postgres save failed for %s: %s", fpath, e)


if __name__ == "__main__":
    run()
