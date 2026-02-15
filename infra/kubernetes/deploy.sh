#!/bin/bash

set -e

NAMESPACE="ai-finance"
ENV=${1:-dev}  # Accept env as parameter (dev, staging, prod)

echo "🚀 Deploying AI Finance Backend to Kubernetes ($ENV)..."
echo ""

# 1. Create namespace
echo "1️⃣  Creating namespace..."
kubectl apply -f namespace.yaml

# 2. Create ConfigMaps
echo "2️⃣  Creating ConfigMaps for $ENV..."
kubectl apply -f configmaps/env-${ENV}.yaml

# 3. Create Secrets
echo "3️⃣  Creating Secrets..."
echo "⚠️  Make sure secrets-template.yaml is configured with real values!"
kubectl apply -f secrets/secrets-template.yaml

# 4. Create RBAC
echo "4️⃣  Creating RBAC..."
kubectl apply -f rbac/serviceaccount.yaml

# 5. Create Deployments
echo "5️⃣  Creating Deployments..."
kubectl apply -f deployments/

# 6. Create Services
echo "6️⃣  Creating Services..."
kubectl apply -f services/

# 7. Create HPA
echo "7️⃣  Creating HorizontalPodAutoscalers..."
kubectl apply -f hpa/

# 8. Create Ingress
echo "8️⃣  Creating Ingress..."
kubectl apply -f ingress/

echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment/auth-service -n $NAMESPACE --timeout=5m

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "   kubectl get all -n $NAMESPACE"
echo "   kubectl get pods -n $NAMESPACE"
echo "   kubectl get svc -n $NAMESPACE"
echo ""