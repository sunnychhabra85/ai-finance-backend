#!/usr/bin/env pwsh
################################################################################
# GitHub Secrets Setup Script
# Configures all required secrets for CI/CD pipelines
################################################################################

param(
    [switch]$DryRun,
    [switch]$ShowCurrent
)

$ErrorActionPreference = "Stop"

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "     GitHub Secrets Setup for CI/CD" -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] GitHub CLI (gh) is not installed!" -ForegroundColor Red
    Write-Host "`nInstall it from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "Or run: winget install GitHub.cli`n" -ForegroundColor Yellow
    exit 1
}

# Check if authenticated
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Not authenticated with GitHub!" -ForegroundColor Red
    Write-Host "`nRun: gh auth login`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] GitHub CLI authenticated`n" -ForegroundColor Green

# Get repository info
$repo = gh repo view --json nameWithOwner -q .nameWithOwner 2>$null
if (-not $repo) {
    Write-Host "[ERROR] Not in a Git repository or no remote configured!" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Repository: $repo`n" -ForegroundColor Cyan

if ($ShowCurrent) {
    Write-Host "Current Secrets:" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Gray
    gh secret list
    Write-Host ""
    exit 0
}

# Required secrets configuration
$secrets = @{
    "AWS_ACCESS_KEY_ID" = @{
        "description" = "AWS Access Key ID for deploying to EKS"
        "required" = $true
        "example" = "AKIAIOSFODNN7EXAMPLE"
    }
    "AWS_SECRET_ACCESS_KEY" = @{
        "description" = "AWS Secret Access Key"
        "required" = $true
        "example" = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        "sensitive" = $true
    }
    "DATABASE_URL" = @{
        "description" = "PostgreSQL connection string for RDS"
        "required" = $true
        "example" = "postgresql://postgres:AiFinance123!@ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com:5432/aifinancedb"
        "sensitive" = $true
    }
    "JWT_SECRET" = @{
        "description" = "Secret key for JWT token generation"
        "required" = $true
        "example" = "your-super-secret-jwt-key-min-32-chars"
        "sensitive" = $true
    }
    "OPENAI_API_KEY" = @{
        "description" = "OpenAI API key for AI service"
        "required" = $false
        "example" = "sk-..."
        "sensitive" = $true
    }
}

Write-Host "Setting up GitHub Secrets..." -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------`n" -ForegroundColor Gray

$successCount = 0
$skipCount = 0
$failCount = 0

foreach ($secretName in $secrets.Keys) {
    $config = $secrets[$secretName]
    
    Write-Host "[SECRET] $secretName" -ForegroundColor Cyan
    Write-Host "   Description: $($config.description)" -ForegroundColor Gray
    
    # Check if secret already exists
    $exists = gh secret list | Select-String -Pattern "^$secretName\s" -Quiet
    
    if ($exists) {
        Write-Host "   Status: Already exists" -ForegroundColor Yellow
        
        $overwrite = Read-Host "   Overwrite? (y/N)"
        if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
            Write-Host "   [SKIP] Skipped`n" -ForegroundColor Gray
            $skipCount++
            continue
        }
    }
    
    # Get value from user
    if ($config.sensitive) {
        $secureValue = Read-Host "   Enter value" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
        $value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    } else {
        $value = Read-Host "   Enter value (example: $($config.example))"
    }
    
    if ([string]::IsNullOrWhiteSpace($value)) {
        if ($config.required) {
            Write-Host "   [ERROR] Required secret - cannot be empty`n" -ForegroundColor Red
            $failCount++
        } else {
            Write-Host "   [SKIP] Optional - skipped`n" -ForegroundColor Gray
            $skipCount++
        }
        continue
    }
    
    # Set the secret
    if ($DryRun) {
        Write-Host "   [DRY RUN] Would set secret" -ForegroundColor Magenta
        $successCount++
    } else {
        try {
            $value | gh secret set $secretName
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   [OK] Set successfully`n" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "   [ERROR] Failed to set`n" -ForegroundColor Red
                $failCount++
            }
        } catch {
            Write-Host "   [ERROR] Error: $_`n" -ForegroundColor Red
            $failCount++
        }
    }
}

# Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  [OK] Successfully set: $successCount" -ForegroundColor Green
Write-Host "  [SKIP] Skipped: $skipCount" -ForegroundColor Gray
if ($failCount -gt 0) {
    Write-Host "  [ERROR] Failed: $failCount" -ForegroundColor Red
}
Write-Host "================================================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[INFO] This was a dry run. Run without -DryRun to apply changes.`n" -ForegroundColor Magenta
}

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify secrets: gh secret list" -ForegroundColor White
Write-Host "  2. Test CI/CD: Push a commit to trigger workflows" -ForegroundColor White
Write-Host "  3. Monitor: Check Actions tab in GitHub`n" -ForegroundColor White
