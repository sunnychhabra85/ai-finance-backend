#!/bin/bash
set -e

# Initialize secrets in EKS cluster
# Usage: ./scripts/setup-secrets.sh [dev|staging|prod]

ENVIRONMENT=${1:-dev}
AWS_REGION="us-east-1"
NAMESPACE="ai-finance"

print_status() {
    echo "✓ $1"
}

print_error() {
    echo "✗ $1"
    exit 1
}

print_status "Setting up secrets for $ENVIRONMENT environment..."

# Get database URL from Secrets Manager
print_status "Fetching secrets from AWS Secrets Manager..."

DATABASE_URL=$(aws secretsmanager get-secret-value \
    --secret-id "ai-finance/$ENVIRONMENT/database-url" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null || echo "")

JWT_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "ai-finance/$ENVIRONMENT/jwt-secret" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null || echo "")

if [ -z "$DATABASE_URL" ]; then
    print_error "Could not fetch DATABASE_URL from Secrets Manager"
fi

print_status "Creating Kubernetes secrets..."

# Create or update secrets
kubectl create secret generic app-secrets \
    --from-literal=DATABASE_URL="$DATABASE_URL" \
    --from-literal=JWT_SECRET="$JWT_SECRET" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

print_status "Secrets configured successfully"

# Verify
kubectl get secrets -n "$NAMESPACE"
