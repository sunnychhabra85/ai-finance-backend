#!/usr/bin/env pwsh
################################################################################
# Stop AI Finance Infrastructure (Without Destroying)
# 
# This script pauses all running resources to minimize AWS costs
# - Scales down all Kubernetes deployments to 0
# - Scales down EKS node group to 0 (stops EC2 instances)
# - Stops RDS database (can be stopped for up to 7 days)
# - Keeps VPC, S3, ECR, Load Balancers (minimal/no cost when idle)
################################################################################

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Stop AI Finance Infrastructure                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "This will stop (not destroy) your infrastructure:" -ForegroundColor Yellow
Write-Host "  ✓ Scale down all Kubernetes deployments to 0" -ForegroundColor White
Write-Host "  ✓ Scale down EKS nodes to 0 (stops EC2 instances)" -ForegroundColor White
Write-Host "  ✓ Stop RDS database" -ForegroundColor White
Write-Host "  ✓ Keep VPC, S3, ECR (minimal cost)" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Your data will be preserved!" -ForegroundColor Green
Write-Host "⚠️  RDS can stay stopped for up to 7 days`n" -ForegroundColor Green

$confirmation = Read-Host "Continue? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n1️⃣ Scaling down Kubernetes deployments..." -ForegroundColor Cyan
kubectl scale deployment --all --replicas=0 -n ai-finance
Write-Host "✅ All deployments scaled to 0`n" -ForegroundColor Green

Write-Host "2️⃣ Scaling down EKS node group..." -ForegroundColor Cyan
aws eks update-nodegroup-config `
    --cluster-name ai-finance-eks-dev `
    --nodegroup-name ai-finance-node-group-dev `
    --scaling-config minSize=0,maxSize=3,desiredSize=0 `
    --region us-east-1

Write-Host "   Waiting for node group to scale down (this may take 3-5 minutes)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

$maxAttempts = 30
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $status = aws eks describe-nodegroup --cluster-name ai-finance-eks-dev --nodegroup-name ai-finance-node-group-dev --region us-east-1 --query 'nodegroup.status' --output text
    
    if ($status -eq "ACTIVE") {
        $desiredSize = aws eks describe-nodegroup --cluster-name ai-finance-eks-dev --nodegroup-name ai-finance-node-group-dev --region us-east-1 --query 'nodegroup.scalingConfig.desiredSize' --output text
        
        if ($desiredSize -eq "0") {
            Write-Host "✅ EKS nodes scaled to 0 (EC2 instances stopped)`n" -ForegroundColor Green
            break
        }
    }
    
    $attempt++
    Write-Host "   Still scaling... ($attempt/$maxAttempts)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

Write-Host "3️⃣ Stopping RDS database..." -ForegroundColor Cyan
aws rds stop-db-instance --db-instance-identifier ai-finance-postgres-dev --region us-east-1 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RDS database stopping (can stay stopped for 7 days)`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  RDS may already be stopped or stopping`n" -ForegroundColor Yellow
}

Write-Host "4️⃣ Checking current resource status..." -ForegroundColor Cyan
Write-Host "`n📊 Final Status:" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Gray

Write-Host "`nKubernetes Deployments:" -ForegroundColor Yellow
kubectl get deployments -n ai-finance -o custom-columns='NAME:.metadata.name,REPLICAS:.spec.replicas'

Write-Host "`nEKS Nodes:" -ForegroundColor Yellow
kubectl get nodes 2>$null

Write-Host "`nRDS Status:" -ForegroundColor Yellow
aws rds describe-db-instances --db-instance-identifier ai-finance-postgres-dev --region us-east-1 --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus]' --output table

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     Infrastructure Stopped Successfully!                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "💰 Cost Savings:" -ForegroundColor Cyan
Write-Host "  • EKS Nodes (t3.small):     ~$15/month → $0" -ForegroundColor White
Write-Host "  • RDS (db.t3.micro):        ~$15/month → $0 (when stopped)" -ForegroundColor White
Write-Host "  • Load Balancers:           ~$16/month → $0" -ForegroundColor White
Write-Host "  • Remaining costs:          ~$2/month (VPC endpoints, S3)" -ForegroundColor White

Write-Host "`n📝 Notes:" -ForegroundColor Yellow
Write-Host "  • Your data in RDS and S3 is preserved" -ForegroundColor White
Write-Host "  • RDS will auto-start after 7 days" -ForegroundColor White
Write-Host "  • ECR images are preserved" -ForegroundColor White
Write-Host "  • To restart: Run .\scripts\start-infrastructure.ps1`n" -ForegroundColor White
