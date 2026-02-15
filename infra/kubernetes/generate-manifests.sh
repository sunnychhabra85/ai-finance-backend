#!/bin/bash

# This script generates deployment and service manifests for all services

SERVICES=(
  "auth-service:3001"
  "upload-service:3002"
  "parser-worker:3003"
  "analytics-service:3004"
  "ai-service:3005"
)

for service_info in "${SERVICES[@]}"; do
  SERVICE_NAME=$(echo $service_info | cut -d: -f1)
  SERVICE_PORT=$(echo $service_info | cut -d: -f2)
  
  echo "Generating manifests for $SERVICE_NAME on port $SERVICE_PORT..."
  
  # Copy auth-service as template and customize
  sed "s/auth-service/$SERVICE_NAME/g; s/3001/$SERVICE_PORT/g" \
    deployments/auth-service-deployment.yaml > deployments/${SERVICE_NAME}-deployment.yaml
  
  sed "s/auth-service/$SERVICE_NAME/g; s/3001/$SERVICE_PORT/g" \
    services/auth-service-svc.yaml > services/${SERVICE_NAME}-svc.yaml
  
  sed "s/auth-service/$SERVICE_NAME/g" \
    hpa/auth-service-hpa.yaml > hpa/${SERVICE_NAME}-hpa.yaml
done

echo "✅ All manifests generated!"