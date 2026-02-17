#!/bin/bash
################################################################################
# GitHub Secrets Setup Script (Bash version)
# For Linux/Mac users
################################################################################

set -e

echo ""
echo "================================================================"
echo "     GitHub Secrets Setup for CI/CD"
echo "================================================================"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "[ERROR] GitHub CLI (gh) is not installed!"
    echo ""
    echo "Install it from: https://cli.github.com/"
    echo "Or run: brew install gh (macOS)"
    echo "Or run: apt install gh (Ubuntu/Debian)"
    echo ""
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "[ERROR] Not authenticated with GitHub!"
    echo ""
    echo "Run: gh auth login"
    echo ""
    exit 1
fi

echo "[OK] GitHub CLI authenticated"
echo ""

# Get repository info
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$repo" ]; then
    echo "[ERROR] Not in a Git repository or no remote configured!"
    exit 1
fi

echo "[INFO] Repository: $repo"
echo ""

# Check for --show-current flag
if [ "$1" == "--show-current" ]; then
    echo "Current Secrets:"
    echo "----------------------------------------------------------------"
    gh secret list
    echo ""
    exit 0
fi

echo "Setting up GitHub Secrets..."
echo "----------------------------------------------------------------"
echo ""

# Helper function to set secret
set_secret() {
    local name=$1
    local description=$2
    local required=$3
    local example=$4
    
    echo "[SECRET] $name"
    echo "   Description: $description"
    
    # Check if exists
    if gh secret list | grep -q "^$name"; then
        echo "   Status: Already exists"
        read -p "   Overwrite? (y/N) " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            echo "   [SKIP] Skipped"
            echo ""
            return
        fi
    fi
    
    # Get value
    read -sp "   Enter value: " value
    echo ""
    
    if [ -z "$value" ]; then
        if [ "$required" == "true" ]; then
            echo "   [ERROR] Required secret - cannot be empty"
            echo ""
            return 1
        else
            echo "   [SKIP] Optional - skipped"
            echo ""
            return 0
        fi
    fi
    
    # Set secret
    if echo "$value" | gh secret set "$name"; then
        echo "   [OK] Set successfully"
        echo ""
        return 0
    else
        echo "   [ERROR] Failed to set"
        echo ""
        return 1
    fi
}

# Set all secrets
SUCCESS=0
FAILED=0

set_secret "AWS_ACCESS_KEY_ID" \
    "AWS Access Key ID for deploying to EKS" \
    "true" \
    "AKIAIOSFODNN7EXAMPLE" && ((SUCCESS++)) || ((FAILED++))

set_secret "AWS_SECRET_ACCESS_KEY" \
    "AWS Secret Access Key" \
    "true" \
    "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" && ((SUCCESS++)) || ((FAILED++))

set_secret "DATABASE_URL" \
    "PostgreSQL connection string for RDS" \
    "true" \
    "postgresql://postgres:password@host:5432/db" && ((SUCCESS++)) || ((FAILED++))

set_secret "JWT_SECRET" \
    "Secret key for JWT token generation (min 32 chars)" \
    "true" \
    "your-super-secret-jwt-key-min-32-chars" && ((SUCCESS++)) || ((FAILED++))

set_secret "OPENAI_API_KEY" \
    "OpenAI API key for AI service (optional)" \
    "false" \
    "sk-..." && ((SUCCESS++)) || true

echo ""
echo "================================================================"
echo "Summary:"
echo "  [OK] Successfully set: $SUCCESS"
if [ $FAILED -gt 0 ]; then
    echo "  [ERROR] Failed: $FAILED"
fi
echo "================================================================"
echo ""

echo "Next Steps:"
echo "  1. Verify secrets: gh secret list"
echo "  2. Test CI/CD: Push a commit to trigger workflows"
echo "  3. Monitor: Check Actions tab in GitHub"
echo ""
