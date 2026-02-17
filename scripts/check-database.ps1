#!/usr/bin/env pwsh
# Script to check database tables data

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('users', 'uploads', 'transactions', 'all')]
    [string]$Table = 'all'
)

$DATABASE_URL = "postgresql://postgres:AiFinance123!@ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com:5432/aifinancedb"

Write-Host "`n=== AI Finance Database Tables ===" -ForegroundColor Green

function Query-Table {
    param($Query, $TableName)
    
    Write-Host "`n📊 $TableName" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────" -ForegroundColor Gray
    
    $result = kubectl run psql-temp --rm -i --image=postgres:15 -n ai-finance --restart=Never -- `
        psql "$DATABASE_URL" -c "$Query" 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $result
    } else {
        Write-Host "Error querying $TableName" -ForegroundColor Red
    }
}

if ($Table -eq 'users' -or $Table -eq 'all') {
    Query-Table 'SELECT id, email, "createdAt" FROM "User" ORDER BY "createdAt" DESC LIMIT 10;' "Users (Last 10)"
}

if ($Table -eq 'uploads' -or $Table -eq 'all') {
    Query-Table 'SELECT id, "userId", "fileName", "fileSize", status, "createdAt" FROM "Upload" ORDER BY "createdAt" DESC LIMIT 10;' "Uploads (Last 10)"
}

if ($Table -eq 'transactions' -or $Table -eq 'all') {
    Query-Table 'SELECT COUNT(*) as total FROM "Transaction";' "Transaction Count"
}

if ($Table -eq 'all') {
    Write-Host "`n📈 Summary Statistics" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────" -ForegroundColor Gray
    
    Query-Table 'SELECT 
        (SELECT COUNT(*) FROM "User") as users,
        (SELECT COUNT(*) FROM "Upload") as uploads,
        (SELECT COUNT(*) FROM "Transaction") as transactions;' "Overall Stats"
}

Write-Host "`n✅ Done!`n" -ForegroundColor Green
