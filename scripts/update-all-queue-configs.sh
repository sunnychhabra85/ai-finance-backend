#!/bin/bash

set -e

echo "🚀 Updating Queue ConfigMaps for All Environments"
echo "=================================================="
echo ""

ENVIRONMENTS=("dev" "staging" "prod")
NAMESPACE="ai-finance"
REGION="us-east-1"

for ENV in "${ENVIRONMENTS[@]}"; do
    echo ""
    echo "════════════════════════════════════════"
    echo "Processing: $ENV"
    echo "════════════════════════════════════════"
    echo ""
    
    # Step 1: Create SQS queues if they don't exist
    echo "Step 1: Ensuring SQS queues exist for $ENV..."
    cd infra/terraform
    
    terraform apply -var="environment=$ENV" -auto-approve 2>/dev/null || true
    
    # Get queue URLs
    TRANSACTIONS_QUEUE=$(terraform output -raw sqs_transactions_queue_url 2>/dev/null || echo "")
    ANALYTICS_QUEUE=$(terraform output -raw sqs_analytics_queue_url 2>/dev/null || echo "")
    
    if [ -z "$TRANSACTIONS_QUEUE" ] || [ -z "$ANALYTICS_QUEUE" ]; then
        echo "❌ Failed to get queue URLs for $ENV"
        continue
    fi
    
    echo "✅ Queue URLs obtained:"
    echo "   Transactions: $TRANSACTIONS_QUEUE"
    echo "   Analytics: $ANALYTICS_QUEUE"
    
    cd ../..
    
    # Step 2: Update ConfigMap file
    echo ""
    echo "Step 2: Updating ConfigMap file for $ENV..."
    
    CONFIGMAP_FILE="infra/kubernetes/configmaps/queue-config-${ENV}.yaml"
    
    if [ ! -f "$CONFIGMAP_FILE" ]; then
        echo "❌ ConfigMap file not found: $CONFIGMAP_FILE"
        continue
    fi
    
    # Use a temporary file for sed to avoid issues
    sed "s|https://sqs.${REGION}.amazonaws.com/[^/]*/ai-finance-transactions-queue-[^ \"]*|${TRANSACTIONS_QUEUE}|g" \
        "$CONFIGMAP_FILE" > "${CONFIGMAP_FILE}.tmp"
    
    sed "s|https://sqs.${REGION}.amazonaws.com/[^/]*/ai-finance-analytics-queue-[^ \"]*|${ANALYTICS_QUEUE}|g" \
        "${CONFIGMAP_FILE}.tmp" > "$CONFIGMAP_FILE"
    
    rm "${CONFIGMAP_FILE}.tmp"
    
    echo "✅ ConfigMap file updated"
    
    # Step 3: Determine kubectl context
    echo ""
    echo "Step 3: Deploying ConfigMap to $ENV cluster..."
    
    if [ "$ENV" = "dev" ]; then
        CONTEXT=""  # Use current context
        CLUSTER_NAME="ai-finance-eks-dev"
    elif [ "$ENV" = "staging" ]; then
        CONTEXT="--context=staging-cluster"
        CLUSTER_NAME="ai-finance-eks-staging"
    elif [ "$ENV" = "prod" ]; then
        CONTEXT="--context=prod-cluster"
        CLUSTER_NAME="ai-finance-eks-prod"
    fi
    
    # Configure kubectl for this environment
    if [ ! -z "$CONTEXT" ]; then
        aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION 2>/dev/null || true
    fi
    
    # Apply ConfigMap
    kubectl apply -f "$CONFIGMAP_FILE" $CONTEXT
    
    echo "✅ ConfigMap deployed"
    
    # Step 4: Restart deployments
    echo ""
    echo "Step 4: Restarting deployments in $ENV..."
    
    kubectl rollout restart deployment -n $NAMESPACE $CONTEXT
    
    # Wait for rollout
    for deployment in upload-service parser-worker analytics-service; do
        kubectl rollout status deployment/$deployment -n $NAMESPACE $CONTEXT --timeout=5m 2>/dev/null || true
    done
    
    echo "✅ Deployments restarted"
    
    # Step 5: Verify
    echo ""
    echo "Step 5: Verifying $ENV configuration..."
    
    kubectl get configmap queue-config -n $NAMESPACE $CONTEXT -o yaml | grep -A 5 "^data:"
    
    echo ""
    echo "✅ $ENV environment configured successfully"
    echo ""
done

echo ""
echo "════════════════════════���═══════════════"
echo "✅ All environments configured!"
echo "════════════════════════════════════════"
echo ""

echo "Summary:"
echo "--------"
for ENV in "${ENVIRONMENTS[@]}"; do
    echo "✅ $ENV - ConfigMap updated and deployed"
done

echo ""
echo "Next steps:"
echo "1. Test each environment:"
echo "   - Dev: curl http://dev-upload-url/health"
echo "   - Stage: curl http://stage-upload-url/health"
echo "   - Prod: curl http://prod-upload-url/health"
echo ""
echo "2. Upload test files and verify transactions appear"
echo ""
echo "3. Monitor queues:"
echo "   aws sqs get-queue-attributes --queue-url <QUEUE_URL> --attribute-names ApproximateNumberOfMessages"
echo ""