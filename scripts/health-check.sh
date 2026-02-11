#!/bin/bash
set -e

# Health check script for services
# Usage: ./scripts/health-check.sh

ENVIRONMENT=${1:-dev}
CLUSTER_NAME="ai-finance-${ENVIRONMENT}"
NAMESPACE="ai-finance"

echo "Health Check for $ENVIRONMENT environment"
echo "=========================================="

# Check cluster connectivity
echo "Checking cluster connectivity..."
kubectl cluster-info

# Check namespace
echo ""
echo "Checking namespace..."
kubectl get namespace "$NAMESPACE"

# Check all deployments
echo ""
echo "Deployment Status:"
kubectl get deployments -n "$NAMESPACE" -o wide

# Check pods
echo ""
echo "Pod Status:"
kubectl get pods -n "$NAMESPACE" -o wide

# Check services
echo ""
echo "Services:"
kubectl get services -n "$NAMESPACE"

# Check ingress
echo ""
echo "Ingress:"
kubectl get ingress -n "$NAMESPACE"

# Check resource usage
echo ""
echo "Resource Usage:"
kubectl top nodes
echo ""
kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "  (Metrics not available yet)"

# Check HPA status
echo ""
echo "Horizontal Pod Autoscaler Status:"
kubectl get hpa -n "$NAMESPACE"

# Port-forward and test endpoints (optional)
echo ""
echo "Testing service endpoints..."

SERVICES=("auth-service" "upload-service" "analytics-service")
for service in "${SERVICES[@]}"; do
    echo "  Testing $service..."
    kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never --command -- \
        curl -s http://"$service":3000/health | grep -q "UP\|status\|Health" && \
        echo "    ✓ $service is healthy" || \
        echo "    ✗ $service health check failed"
done

echo ""
echo "Health check complete!"
