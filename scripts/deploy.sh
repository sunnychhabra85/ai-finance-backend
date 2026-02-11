#!/bin/bash
set -e

# Deploy script for AI Finance Backend
# Usage: ./scripts/deploy.sh [dev|staging|prod]

ENVIRONMENT=${1:-dev}
AWS_REGION="us-east-1"
CLUSTER_NAME="ai-finance-${ENVIRONMENT}"
KUSTOMIZE_PATH="k8s/overlays/${ENVIRONMENT}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Use: dev, staging, or prod"
fi

print_status "Deploying to $ENVIRONMENT environment..."

# Check prerequisites
command -v aws >/dev/null 2>&1 || print_error "AWS CLI is not installed"
command -v kubectl >/dev/null 2>&1 || print_error "kubectl is not installed"
command -v kustomize >/dev/null 2>&1 || print_error "kustomize is not installed"

# Authenticate with AWS
print_status "Configuring AWS credentials (using IRSA or AWS_PROFILE)..."
aws sts get-caller-identity > /dev/null || print_error "AWS authentication failed"

# Update kubeconfig
print_status "Updating kubeconfig for cluster: $CLUSTER_NAME..."
aws eks update-kubeconfig \
    --name "$CLUSTER_NAME" \
    --region "$AWS_REGION" || print_error "Failed to update kubeconfig"

# Verify cluster connectivity
print_status "Verifying cluster connectivity..."
kubectl cluster-info > /dev/null || print_error "Cannot connect to cluster"

# Create namespace if not exists
print_status "Ensuring namespace ai-finance exists..."
kubectl create namespace ai-finance --dry-run=client -o yaml | kubectl apply -f - || true

# Load environment variables
if [ -f ".env.${ENVIRONMENT}" ]; then
    print_status "Loading environment variables from .env.${ENVIRONMENT}..."
    export $(cat ".env.${ENVIRONMENT}" | grep -v '^#' | xargs)
fi

# Deploy using Kustomize
print_status "Building and deploying manifests from $KUSTOMIZE_PATH..."
kustomize build "$KUSTOMIZE_PATH" | kubectl apply -f - || print_error "Failed to apply manifests"

print_status "Manifests applied successfully"

# Wait for deployments
print_status "Waiting for deployments to roll out..."
SERVICES=("auth-service" "upload-service" "analytics-service" "parser-worker")

for service in "${SERVICES[@]}"; do
    echo "  ⏳ Waiting for $service..."
    kubectl rollout status deployment/"$service" -n ai-finance --timeout=5m || print_warning "Timeout waiting for $service"
done

print_status "Rollout complete"

# Verify deployments
print_status "Verifying deployment status..."
kubectl get deployments -n ai-finance -o wide

# Get endpoints
print_status "Service endpoints:"
kubectl get ingress -n ai-finance

# Summary
echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER_NAME"
echo "Namespace: ai-finance"
echo ""
echo "Deployed Services:"
kubectl get pods -n ai-finance -l app --no-headers | awk '{print "  - " $1}'
echo ""
print_status "Deployment completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Monitor deployment: kubectl logs -f deployment/auth-service -n ai-finance"
echo "  2. Check health: kubectl exec -it <pod-name> -n ai-finance -- curl localhost:3000/health"
echo "  3. View all resources: kubectl get all -n ai-finance"
