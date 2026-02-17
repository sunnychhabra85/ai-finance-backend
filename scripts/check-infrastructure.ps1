#!/usr/bin/env pwsh
################################################################################
# Infrastructure Status Check
################################################################################

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     AI Finance Infrastructure Status                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📊 EKS Node Group:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray
aws eks describe-nodegroup `
    --cluster-name ai-finance-eks-dev `
    --nodegroup-name ai-finance-node-group-dev `
    --region us-east-1 `
    --query 'nodegroup.[status,scalingConfig]' `
    --output table

Write-Host "`n📊 EKS Nodes:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray
kubectl get nodes 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No nodes running (scaled to 0)" -ForegroundColor Gray
}

Write-Host "`n📊 RDS Database:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray
aws rds describe-db-instances `
    --db-instance-identifier ai-finance-postgres-dev `
    --region us-east-1 `
    --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass,AllocatedStorage]' `
    --output table

Write-Host "`n📊 Kubernetes Deployments:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray
kubectl get deployments -n ai-finance 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cannot connect to cluster (nodes may be stopped)" -ForegroundColor Gray
}

Write-Host "`n📊 Pods:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray
kubectl get pods -n ai-finance 2>$null

Write-Host "`n📊 Load Balancers:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray
aws elbv2 describe-load-balancers `
    --region us-east-1 `
    --query 'LoadBalancers[?contains(LoadBalancerName, `ai-finance`)].[LoadBalancerName,State.Code,Type]' `
    --output table

Write-Host "`n💰 Estimated Current Costs:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────" -ForegroundColor Gray

$nodeCount = (kubectl get nodes --no-headers 2>$null | Measure-Object | Select-Object -ExpandProperty Count)
$rdsStatus = aws rds describe-db-instances --db-instance-identifier ai-finance-postgres-dev --region us-east-1 --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null
$lbCount = (aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `ai-finance`)]' --output json 2>$null | ConvertFrom-Json | Measure-Object | Select-Object -ExpandProperty Count)

$eksCost = if ($nodeCount -gt 0) { $nodeCount * 15 } else { 0 }
$rdsCost = if ($rdsStatus -eq "available") { 15 } else { 0 }
$lbCost = $lbCount * 16
$otherCost = 2

$totalCost = $eksCost + $rdsCost + $lbCost + $otherCost

Write-Host "EKS Control Plane:     Free (covered by AWS)" -ForegroundColor White
Write-Host "EKS Nodes ($nodeCount):         ~`$$eksCost/month" -ForegroundColor White
Write-Host "RDS ($rdsStatus):     ~`$$rdsCost/month" -ForegroundColor White
Write-Host "Load Balancers ($lbCount):     ~`$$lbCost/month" -ForegroundColor White
Write-Host "VPC/S3/ECR:            ~`$$otherCost/month" -ForegroundColor White
Write-Host "─────────────────────────────────" -ForegroundColor Gray
Write-Host "Total Estimated:       ~`$$totalCost/month`n" -ForegroundColor $(if ($totalCost -gt 10) { "Yellow" } else { "Green" })

Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "  • To stop:  .\scripts\stop-infrastructure.ps1" -ForegroundColor White
Write-Host "  • To start: .\scripts\start-infrastructure.ps1" -ForegroundColor White
Write-Host "  • To destroy all: cd infra/terraform; terraform destroy`n" -ForegroundColor White
