# Stock ETL: 

**Goal:** a fully documented, runnable starter repo that demonstrates a Python ETL which pulls Stock market data from a public financial API (AlphaVantage), transforms it, and saves it to a data lake (S3 or local) + RDS (PostgreSQL). The project includes:
- Docker 
- GitHub Actions CI/CD, 
- Terraform(IaC)
- AWS (S3 + RDS + ECS/ECR) 
- Prefect/Airflow, 
- FastAPI query layer - To help non-technical. 
 
---
## Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- AlphaVantage API Key → [Get one here](https://www.alphavantage.co/support/#api-key)

## Why this API choice
- We'll fetch Stock Symbol (ASX, IBM, etc.) price and fundamentals from a free financial API, the starter uses **AlphaVantage** by default. The repo includes code and docs so you can swap providers easily.

---

## What I created in this 
- A complete repo scaffold (files shown below) with **starter code** you can run locally.
- **Dockerfiles** and **Docker-compose** for the ETL and the API service.
- **GitHub Actions** workflows for test / build / Docker push / (skeleton) deploy.
- **Terraform** to create **AWS S3 and RDS** — ready for you to `terraform apply` when you provide AWS creds.
- **Orchestration examples: a Prefect flow and an Airflow DAG.** - Still considering and implementing.
- README with step-by-step run instructions, examples and tradeoffs.

---

## Repo file structure

```
stock-etl/
├── README.md
├── etl/
│   ├── app/
│   │   ├── etl.py
│   │   ├── fetcher.py
│   │   ├── transform.py
│   │   ├── loader.py
│   │   └── config.py
│   ├── tests/
│   │   └── test_transform.py
│   └── Dockerfile
├── api/
│   ├── app.py
│   └── Dockerfile
├── infra/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
├── .github/workflows/
│   ├── ci.yml
│   └── deploy.yml
└── docker-compose.yml
```

---

## Important: Live API keys and cloud creds
To run end-to-end against live AlphaVantage data you will need an API key from AlphaVantage (free tier). The README shows how to set `ALPHAVANTAGE_API_KEY` and optional AWS credentials. The project is safe to run locally without cloud creds — data will be written to `./data/`.

---

This project demonstrates a small data platform: a Python ETL that fetches daily market data, transforms it, and writes Parquet files to a data lake (local or S3 and RDS). It includes Dockerfiles, CI/CD workflows, Terraform skeleton and examples for orchestration.

## Quickstart (local)

1. Copy `.env.example` to `.env` and set `ALPHAVANTAGE_API_KEY` (get one at **https://www.alphavantage.co/support/#api-key**).
2. Build and run the ETL container locally with the FastAPI server:

```bash
cd etl
docker compose up --build
```

3. Inspect `./etl/data/` for output Parquet/CSV files.
4. Search to access the FastAPI: **http://localhost:8000**
5. You can exec into the docker container and visualise the data better with postgres. 
``` bash
docker exec -it stock-etl-postgres-1 psql -U etl_user -d quotes
# PostgreSQL commands as you are in the container and in the database.
SELECT * FROM quotes WHERE symbol = 'IBM' LIMIT 10;
# You can change IBM to any of the symbols you want and specify it in the `.env`
```


## CI/CD and Infra
- `.github/workflows/ci.yml` runs tests, lint and builds Docker images.
- `infra/terraform` contains a skeleton to provision S3 and IAM roles.

## Swap API provider
- The fetcher is provider-agnostic: see `etl/app/fetcher.py` and set `PROVIDER=finnhub` (need to pay for this API) or `provider=alphavantage`. You may need to refactor the python code in some areas. 

---

---

## What does this project show?

- This project is essentially a mini data platform. It covers several key data engineering concepts that employers like Macquarie want to see:

### 1. ETL (Extract, Transform and Load)
- Extract: Pulls stock price data from the AlphaVantage API (or similar financial data providers).
- Transform: Cleans the raw API response, structures it into a tabular format with fields like symbol, open, high, low, close, volume, timestamp.
- Load: Saves the cleaned data in two ways:
  - Postgres Database (RDS-ready) → for relational queries and analytics.
  - Parquet files (Apache Parquet = columnar storage) → efficient, compressed storage, ideal for data lakes / S3.
- Why both?
  - Parquet/S3 = scalable, cheap, great for long-term archival + batch analytics (e.g., Athena/Spark).
  - Postgres/RDS = structured queries, API layer, easy access for dashboards. This dual-storage approach mirrors real-world data engineering patterns (data warehouse + data lake).

### 2. Containerisation with Docker & Orchestration with Docker Compose
- Each service is isolated:
  - etl service → runs the extraction & loading pipeline.
  - postgres service → acts as the target database.
  - api service (FastAPI) → exposes data via REST API endpoints.

Docker Compose ties them together so docker compose up runs the whole stack.
This shows you understand how to design modular, portable data platforms.

### 3. Infrastructure as Code (Terraform + AWS)
- Terraform provisions:
  - S3 bucket → to store parquet files.
  - RDS (Postgres) → production-ready managed database.

### 4. CI/CD (GitHub Actions)
- CI pipeline: runs tests (e.g., pytest on transforms) and builds docker image.
- CD pipeline: builds Docker images and runs infra workflow (**Terrafrom**)
 
This demonstrates production workflows and manage continuous delivery.

### 5. Data Importance
The dataset you’re working with:
- Provides daily stock prices (open, high, low, close, volume).
- Lets analysts:
  - Identify trends (e.g., is ASX trending up/down).
  - Compare multiple stocks (IBM vs MQG.AX, etc).
  - Build dashboards for trading signals or market insights.

This is a core financial dataset — highly relevant for financial services


---

## Next steps:
- Add dbt model and sample transformations.
- Extend Terraform to provision ECR and an ECS/Fargate service.
- Add GitHub Actions to build and push Docker images to ECR.
- Convert ETL to a Prefect flow and show how to register it.

---


## Postgresql Commands

```psql
SELECT * FROM quotes WHERE symbol = 'IBM' LIMIT 10;
# You can change IBM to any of the symbols you want and specify it in the `.env`
```
