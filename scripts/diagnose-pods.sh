#!/bin/bash

echo "🔍 Diagnosing Pod Issues..."
echo "=============================================="
echo ""

NAMESPACE="ai-finance"
REGION="us-east-1"

# Get detailed pod information
echo "1️⃣  POD STATUS:"
echo "────────────────────────────────────────────"
kubectl get pods -n $NAMESPACE -o wide
echo ""

# Describe first pod to see errors
echo "2️⃣  POD DETAILED INFORMATION:"
echo "────────────────────────────────────────────"
FIRST_POD=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | head -1 | awk '{print $1}')
if [ ! -z "$FIRST_POD" ]; then
    echo "Describing pod: $FIRST_POD"
    kubectl describe pod $FIRST_POD -n $NAMESPACE
else
    echo "No pods found"
fi
echo ""

# Check pod events
echo "3️⃣  POD EVENTS (Last 20):"
echo "────────────────────────────────────────────"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20
echo ""

# Check node status
echo "4️⃣  NODE STATUS:"
echo "────────────────────────────────────────────"
kubectl get nodes -o wide
kubectl describe nodes
echo ""

# Check EKS cluster status
echo "5️⃣  EKS CLUSTER STATUS:"
echo "────────────────────────────────────────────"
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status'
echo ""

# Check resource usage
echo "6️⃣  RESOURCE USAGE:"
echo "────────────────────────────────────────────"
echo "Node resources:"
kubectl top nodes 2>/dev/null || echo "Metrics not available yet"
echo ""

echo "Pod resource requests:"
kubectl get pods -n $NAMESPACE -o json | jq '.items[] | {name: .metadata.name, requests: .spec.containers[].resources.requests}'
echo ""

# Check image pull status
echo "7️⃣  IMAGE PULL STATUS:"
echo "────────────────────────────────────────────"
kubectl get pods -n $NAMESPACE -o json | jq '.items[] | {name: .metadata.name, image: .spec.containers[].image, status: .status.containerStatuses[]}'
echo ""

# Check service account
echo "8️⃣  SERVICE ACCOUNT:"
echo "────────────────────────────────────────────"
kubectl get serviceaccount -n $NAMESPACE
kubectl get secrets -n $NAMESPACE
echo ""

# Check ECR images
echo "9️⃣  ECR IMAGES AVAILABILITY:"
echo "────────────────────────────────────────────"
aws ecr list-images --repository-name ai-finance/auth-service --region $REGION --query 'imageIds[*].imageTag'
echo ""

# Check logs if any pod exists
echo "🔟 POD LOGS (Last 50 lines):"
echo "────────────────────────────────────────────"
for pod in $(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | awk '{print $1}'); do
    echo "Pod: $pod"
    kubectl logs $pod -n $NAMESPACE --tail=20 2>&1 || echo "No logs available"
    echo "---"
done