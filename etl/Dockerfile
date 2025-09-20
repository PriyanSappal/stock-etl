FROM python:3.10-slim

# Set working directory inside container
WORKDIR /app

# Install system deps if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your ETL app code
COPY app/ app/

# Set default command to run ETL
CMD ["python", "-m", "app.etl"]