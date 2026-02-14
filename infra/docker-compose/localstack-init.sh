#!/bin/bash

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
sleep 10

# Initialize AWS resources locally
echo "Creating S3 bucket and SQS queue..."

# Create S3 bucket for file uploads
aws --endpoint-url=http://localhost:4566 \
    --region us-east-1 \
    s3 mb s3://ai-finance-uploads \
    --access-key test \
    --secret-key test

# Create SQS queue for document processing
aws --endpoint-url=http://localhost:4566 \
    --region us-east-1 \
    sqs create-queue \
    --queue-name document-processing \
    --access-key test \
    --secret-key test

echo "AWS resources created successfully!"