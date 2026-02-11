#!/bin/bash
set -e

# Setup Kubernetes cluster on EKS
# Usage: ./scripts/setup-clusters.sh

AWS_REGION="us-east-1"
ENVIRONMENTS=("dev" "staging" "prod")

print_status() {
    echo "✓ $1"
}

print_error() {
    echo "✗ $1"
    exit 1
}

print_status "Setting up EKS clusters..."

for ENV in "${ENVIRONMENTS[@]}"; do
    CLUSTER_NAME="ai-finance-${ENV}"
    
    print_status "Checking cluster: $CLUSTER_NAME..."
    
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null > /dev/null; then
        print_status "Cluster $CLUSTER_NAME already exists"
    else
        print_status "Creating cluster $CLUSTER_NAME..."
        
        # This should be done via Terraform, but shown here for manual setup
        aws eks create-cluster \
            --name "$CLUSTER_NAME" \
            --region "$AWS_REGION" \
            --kubernetes-network-config serviceIpv4Cidr=10.100.0.0/16 \
            --logging '{"clusterLogging":[{"types":["api","audit","authenticator"],"enabled":true}]}' \
            --tags Environment="$ENV"
    fi
done

print_status "Cluster setup complete"
print_status "Setup ECR repositories next using: ./scripts/setup-ecr.sh"
