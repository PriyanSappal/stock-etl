#!/bin/bash
set -e

# Update system and install dependencies
yum update -y
amazon-linux-extras install docker -y
yum install -y git postgresql  # git for cloning, psql for health checks

# Start docker
service docker start
usermod -aG docker ec2-user

# Install docker compose
curl -L "https://github.com/docker/compose/releases/download/2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Export env vars for containers (these come from Terraform templatefile)
echo "POSTGRES_USER=${db_username}" >> /etc/environment
echo "POSTGRES_PASSWORD=${db_password}" >> /etc/environment
echo "POSTGRES_DB=${db_name}" >> /etc/environment
echo "POSTGRES_HOST=${db_endpoint}" >> /etc/environment
echo "POSTGRES_PORT=${db_port}" >> /etc/environment
echo "S3_BUCKET=${bucket_name}" >> /etc/environment
echo "PROVIDER=${api_provider}" >> /etc/environment
echo "SYMBOL=${symbol}" >> /etc/environment
echo "ALPHAVANTAGE_API_KEY=${api_key}" >> /etc/environment
echo "GF_SECURITY_ADMIN_USER=${grafana_user}" >> /etc/environment
echo "GF_SECURITY_ADMIN_PASSWORD=${grafana_pass}" >> /etc/environment

# Make sure env vars are available immediately in this session
source /etc/environment

# Wait until RDS is ready (max 15 minutes)
echo "Waiting for RDS to become available..."
for i in {1..90}; do
  if PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -p $POSTGRES_PORT -c '\q' >/dev/null 2>&1; then
    echo "✅ RDS is available"
    break
  fi
  echo "RDS not ready yet... retrying in 10s"
  sleep 10
done

# Clone repo and start docker-compose
cd /home/ec2-user
git clone https://github.com/PriyanSappal/stock-etl.git
cd stock-etl

/usr/local/bin/docker-compose up -d
