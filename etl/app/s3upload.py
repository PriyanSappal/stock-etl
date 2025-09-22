import boto3
import os

AWS_REGION = os.getenv("AWS_REGION", "eu-west-2")

s3 = boto3.client("s3", region_name=AWS_REGION)

def upload_to_s3(file_path: str, key: str):
    """Upload a file to S3 at s3://S3_BUCKET/key"""
    bucket = os.getenv("S3_BUCKET")
    if not bucket:
        raise ValueError("S3_BUCKET environment variable is not set")

    s3.upload_file(file_path, bucket, key)
    print(f"✅ Uploaded {file_path} → s3://{bucket}/{key}")