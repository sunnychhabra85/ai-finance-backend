#!/usr/bin/env pwsh
################################################################################
# Database Connection Helper for pgAdmin4
# 
# Creates a temporary proxy pod to connect to RDS database
################################################################################

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     AI Finance Database Connection Helper                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📊 Database Information:" -ForegroundColor Green
Write-Host "  RDS Endpoint:  ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com" -ForegroundColor White
Write-Host "  Database Name: aifinancedb" -ForegroundColor White
Write-Host "  Username:      postgres" -ForegroundColor White
Write-Host "  Password:      AiFinance123!" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔌 Starting database proxy..." -ForegroundColor Green
Write-Host "  Creating temporary pod with socat..." -ForegroundColor Gray

# Create a temporary pod with socat to proxy the connection
$podYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: db-proxy-temp
  namespace: ai-finance
spec:
  containers:
  - name: socat
    image: alpine/socat
    command: ['socat', 'TCP-LISTEN:5432,fork,reuseaddr', 'TCP:ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com:5432']
    ports:
    - containerPort: 5432
"@

# Save and apply the pod
$podYaml | Out-File -FilePath "$env:TEMP\db-proxy-temp.yaml" -Encoding UTF8
kubectl apply -f "$env:TEMP\db-proxy-temp.yaml" | Out-Null

Write-Host "  Waiting for pod to start..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Host "`n✅ Use these settings in pgAdmin4:" -ForegroundColor Green
Write-Host "  Host:          localhost" -ForegroundColor Cyan
Write-Host "  Port:          5433" -ForegroundColor Cyan
Write-Host "  Database:      aifinancedb" -ForegroundColor Cyan
Write-Host "  Username:      postgres" -ForegroundColor Cyan
Write-Host "  Password:      AiFinance123!" -ForegroundColor Yellow
Write-Host ""

Write-Host "⚠️  Keep this terminal running while using pgAdmin4" -ForegroundColor Yellow
Write-Host "⚠️  Press Ctrl+C when done (will cleanup the proxy pod)`n" -ForegroundColor Yellow

# Handle cleanup on exit
$cleanupScript = {
    Write-Host "`n🧹 Cleaning up proxy pod..." -ForegroundColor Yellow
    kubectl delete pod db-proxy-temp -n ai-finance 2>$null
    Remove-Item "$env:TEMP\db-proxy-temp.yaml" -ErrorAction SilentlyContinue
}
Register-EngineEvent PowerShell.Exiting -Action $cleanupScript | Out-Null

try {
    # Start port forwarding
    kubectl port-forward -n ai-finance pod/db-proxy-temp 5433:5432
} finally {
    & $cleanupScript
}


