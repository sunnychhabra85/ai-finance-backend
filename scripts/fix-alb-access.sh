#!/bin/bash

set -e

echo "🔧 Creating LoadBalancer Services for EKS"
echo "=========================================="
echo ""

NAMESPACE="ai-finance"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Checking current services${NC}"
kubectl get svc -n $NAMESPACE
echo ""

echo -e "${YELLOW}Step 2: Deleting existing services (if any)${NC}"
kubectl delete svc auth-service -n $NAMESPACE --ignore-not-found=true
kubectl delete svc upload-service -n $NAMESPACE --ignore-not-found=true
kubectl delete svc parser-worker -n $NAMESPACE --ignore-not-found=true
kubectl delete svc analytics-service -n $NAMESPACE --ignore-not-found=true
kubectl delete svc ai-service -n $NAMESPACE --ignore-not-found=true

echo "Waiting for services to be deleted..."
sleep 10

echo -e "${GREEN}✅ Services deleted${NC}"
echo ""

echo -e "${YELLOW}Step 3: Creating new LoadBalancer services${NC}"
echo ""

# Array of services with port mappings
declare -a SERVICES=(
    "auth-service:3001"
    "upload-service:3002"
    "parser-worker:3003"
    "analytics-service:3004"
    "ai-service:3005"
)

for service_info in "${SERVICES[@]}"; do
    SERVICE_NAME=$(echo $service_info | cut -d: -f1)
    SERVICE_PORT=$(echo $service_info | cut -d: -f2)
    
    echo "Creating LoadBalancer for $SERVICE_NAME (port $SERVICE_PORT)..."
    
    kubectl expose deployment $SERVICE_NAME \
        -n $NAMESPACE \
        --type=LoadBalancer \
        --port=80 \
        --target-port=$SERVICE_PORT \
        --name=$SERVICE_NAME
    
    echo -e "${GREEN}✅ $SERVICE_NAME created${NC}"
done

echo ""
echo -e "${YELLOW}Step 4: Verifying services${NC}"
kubectl get svc -n $NAMESPACE
echo ""

echo -e "${YELLOW}Step 5: Waiting for ALBs to get IP/DNS (2-3 minutes)...${NC}"
echo "This can take a while, please be patient..."
echo ""

# Wait for all services to get external IPs/hostnames
for i in {1..60}; do
    PENDING=0
    READY=0
    
    for service_info in "${SERVICES[@]}"; do
        SERVICE_NAME=$(echo $service_info | cut -d: -f1)
        EXTERNAL_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        
        if [ -z "$EXTERNAL_IP" ]; then
            PENDING=$((PENDING + 1))
        else
            READY=$((READY + 1))
        fi
    done
    
    echo "Attempt $i/60: $READY services ready, $PENDING still pending..."
    
    if [ $PENDING -eq 0 ]; then
        echo -e "${GREEN}✅ All services ready!${NC}"
        break
    fi
    
    sleep 5
done

echo ""
echo -e "${YELLOW}Step 6: Getting service URLs${NC}"
echo ""

# Save URLs to file
echo "Service URLs" > service-urls.txt
echo "============" >> service-urls.txt
echo "" >> service-urls.txt

for service_info in "${SERVICES[@]}"; do
    SERVICE_NAME=$(echo $service_info | cut -d: -f1)
    SERVICE_PORT=$(echo $service_info | cut -d: -f2)
    
    EXTERNAL_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending")
    
    echo -e "${GREEN}$SERVICE_NAME:${NC}"
    echo "  Service URL: http://$EXTERNAL_IP"
    echo "  Health Check: http://$EXTERNAL_IP/health"
    echo ""
    
    echo "$SERVICE_NAME:" >> service-urls.txt
    echo "  URL: http://$EXTERNAL_IP" >> service-urls.txt
    echo "  Health: http://$EXTERNAL_IP/health" >> service-urls.txt
    echo "" >> service-urls.txt
done

echo -e "${YELLOW}Step 7: Testing services${NC}"
echo ""

# Test auth-service
AUTH_URL=$(kubectl get svc auth-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ ! -z "$AUTH_URL" ]; then
    echo "Testing auth-service: http://$AUTH_URL/health"
    
    # Try to curl with timeout
    if timeout 5 curl -s http://$AUTH_URL/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Auth service is responding!${NC}"
    else
        echo -e "${YELLOW}⏳ Service not responding yet (may need more warmup time)${NC}"
    fi
else
    echo -e "${YELLOW}⏳ Auth service URL still pending${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ LoadBalancer services created!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📋 Summary:${NC}"
echo "  Namespace: $NAMESPACE"
echo "  Services Created: ${#SERVICES[@]}"
echo "  URLs saved to: service-urls.txt"
echo ""

echo -e "${YELLOW}🧪 Test commands:${NC}"
echo ""

for service_info in "${SERVICES[@]}"; do
    SERVICE_NAME=$(echo $service_info | cut -d: -f1)
    EXTERNAL_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "PENDING")
    
    if [ "$EXTERNAL_IP" != "PENDING" ]; then
        echo "  curl http://$EXTERNAL_IP/health"
    fi
done

echo ""
echo -e "${YELLOW}📝 View all URLs:${NC}"
echo "  cat service-urls.txt"
echo ""

echo -e "${YELLOW}🔍 View service details:${NC}"
echo "  kubectl get svc -n $NAMESPACE"
echo "  kubectl describe svc auth-service -n $NAMESPACE"
echo ""

echo -e "${YELLOW}📊 View pod to service mapping:${NC}"
echo "  kubectl get endpoints -n $NAMESPACE"
echo ""