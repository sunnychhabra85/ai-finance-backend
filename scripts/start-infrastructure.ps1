#!/usr/bin/env pwsh
################################################################################
# Start AI Finance Infrastructure
# 
# This script resumes all stopped resources
# - Starts RDS database
# - Scales up EKS node group to 1
# - Scales up all Kubernetes deployments to 1 replica
################################################################################

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Start AI Finance Infrastructure                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "1️⃣ Starting RDS database..." -ForegroundColor Cyan
aws rds start-db-instance --db-instance-identifier ai-finance-postgres-dev --region us-east-1 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RDS database starting...`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  RDS may already be running`n" -ForegroundColor Yellow
}

Write-Host "   Waiting for RDS to become available (this may take 3-5 minutes)..." -ForegroundColor Gray
$maxAttempts = 40
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $status = aws rds describe-db-instances --db-instance-identifier ai-finance-postgres-dev --region us-east-1 --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null
    
    if ($status -eq "available") {
        Write-Host "✅ RDS database is available`n" -ForegroundColor Green
        break
    }
    
    $attempt++
    Write-Host "   RDS Status: $status ($attempt/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

Write-Host "2️⃣ Scaling up EKS node group..." -ForegroundColor Cyan
aws eks update-nodegroup-config `
    --cluster-name ai-finance-eks-dev `
    --nodegroup-name ai-finance-node-group-dev `
    --scaling-config minSize=1,maxSize=3,desiredSize=1 `
    --region us-east-1

Write-Host "   Waiting for nodes to start (this may take 3-5 minutes)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

$maxAttempts = 30
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $nodes = kubectl get nodes --no-headers 2>$null
    
    if ($nodes) {
        $readyNodes = kubectl get nodes --no-headers | Select-String "Ready" | Measure-Object | Select-Object -ExpandProperty Count
        if ($readyNodes -gt 0) {
            Write-Host "✅ EKS nodes are ready`n" -ForegroundColor Green
            break
        }
    }
    
    $attempt++
    Write-Host "   Still starting nodes... ($attempt/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

Write-Host "3️⃣ Scaling up Kubernetes deployments..." -ForegroundColor Cyan
kubectl scale deployment ai-service --replicas=1 -n ai-finance
kubectl scale deployment analytics-service --replicas=1 -n ai-finance
kubectl scale deployment auth-service --replicas=1 -n ai-finance
kubectl scale deployment parser-worker --replicas=1 -n ai-finance
kubectl scale deployment upload-service --replicas=1 -n ai-finance

Write-Host "✅ All deployments scaled to 1 replica`n" -ForegroundColor Green

Write-Host "   Waiting for pods to start (this may take 2-3 minutes)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

kubectl get pods -n ai-finance

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     Infrastructure Started Successfully!                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📊 Service Status:" -ForegroundColor Cyan
kubectl get deployments -n ai-finance

Write-Host "`n🔗 Service URLs:" -ForegroundColor Cyan
kubectl get svc -n ai-finance -o custom-columns='NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].hostname' | Select-String "LoadBalancer"

Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "  • Check pod logs: kubectl logs -f <pod-name> -n ai-finance" -ForegroundColor White
Write-Host "  • Test services with the URLs above" -ForegroundColor White
Write-Host "  • To stop again: Run .\scripts\stop-infrastructure.ps1`n" -ForegroundColor White
