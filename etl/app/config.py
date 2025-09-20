import os
from dotenv import load_dotenv

load_dotenv()

ALPHAVANTAGE_API_KEY = os.getenv('ALPHAVANTAGE_API_KEY')
PROVIDER = os.getenv('PROVIDER')
OUTPUT_DIR = os.getenv('OUTPUT_DIR')
SYMBOL = os.getenv('SYMBOL').split(",")

# Postgres connection
POSTGRES_USER = os.getenv('POSTGRES_USER')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD')
POSTGRES_DB = os.getenv('POSTGRES_DB')
POSTGRES_HOST = os.getenv('POSTGRES_HOST')
POSTGRES_PORT = os.getenv('POSTGRES_PORT')

