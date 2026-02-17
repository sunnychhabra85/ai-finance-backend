#!/bin/bash

# Script to check database tables data

DATABASE_URL="postgresql://postgres:AiFinance123!@ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com:5432/aifinancedb"

echo -e "\n=== AI Finance Database Tables ==="

# Function to run queries
query_table() {
    local query=$1
    local table_name=$2
    
    echo -e "\n📊 $table_name"
    echo "─────────────────────────────────"
    
    kubectl run psql-temp --rm -i --image=postgres:15 -n ai-finance --restart=Never -- \
        psql "$DATABASE_URL" -c "$query" 2>/dev/null || echo "Error querying $table_name"
}

# Check Users
query_table 'SELECT id, email, "createdAt" FROM "User" ORDER BY "createdAt" DESC LIMIT 10;' "Users (Last 10)"

# Check Uploads
query_table 'SELECT id, "userId", "fileName", "fileSize", status, "createdAt" FROM "Upload" ORDER BY "createdAt" DESC LIMIT 10;' "Uploads (Last 10)"

# Check Transactions
query_table 'SELECT COUNT(*) as total FROM "Transaction";' "Transaction Count"

# Summary
echo -e "\n📈 Summary Statistics"
echo "─────────────────────────────────"
query_table 'SELECT 
    (SELECT COUNT(*) FROM "User") as users,
    (SELECT COUNT(*) FROM "Upload") as uploads,
    (SELECT COUNT(*) FROM "Transaction") as transactions;' "Overall Stats"

echo -e "\n✅ Done!\n"
