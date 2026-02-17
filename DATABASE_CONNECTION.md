# 🔌 Connecting to AI Finance Database

This guide shows how to connect pgAdmin4 (or any PostgreSQL client) to your RDS database.

## Quick Setup Options

### ⚡ Option 1: Temporary Proxy Pod (Recommended)

**Note**: Requires free node capacity. If your node is full, use Option 2 first.

```powershell
.\scripts\db-connect.ps1
```

Then in pgAdmin4:
- **Host**: `localhost`
- **Port**: `5433`
- **Database**: `aifinancedb`
- **Username**: `postgres`
- **Password**: `AiFinance123!`

---

### 🔄 Option 2: Scale Down & Create Proxy (If Node Full)

```powershell
# Step 1: Temporarily scale down parser-worker to free resources
kubectl scale deployment parser-worker --replicas=0 -n ai-finance

# Step 2: Run the connection script
.\scripts\db-connect.ps1

# Step 3: When done, scale parser-worker back up
kubectl scale deployment parser-worker --replicas=1 -n ai-finance
```

---

### 💻 Option 3: Direct psql Terminal Access

For quick queries without pgAdmin4:

```powershell
# Connect to database via temporary pod
kubectl run psql-client --rm -it `
  --image=postgres:15 `
  -n ai-finance `
  --restart=Never `
  -- psql "postgresql://postgres:AiFinance123!@ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com:5432/aifinancedb"
```

Once connected:
```sql
-- List all tables
\dt

-- View users
SELECT * FROM "User";

-- View uploads
SELECT * FROM "Upload";

-- View transactions
SELECT * FROM "Transaction";

-- Count all records
SELECT 
    (SELECT COUNT(*) FROM "User") as users,
    (SELECT COUNT(*) FROM "Upload") as uploads,
    (SELECT COUNT(*) FROM "Transaction") as transactions;

-- Exit
\q
```

---

### 📊 Option 4: Quick Data Inspection Script

View data without GUI:

```powershell
# View all tables
.\scripts\check-database.ps1

# View specific table
.\scripts\check-database.ps1 -Table users
.\scripts\check-database.ps1 -Table uploads
.\scripts\check-database.ps1 -Table transactions
```

---

## 🔐 Connection Details

| Field | Value |
|-------|-------|
| **Host (External)** | `ai-finance-postgres-dev.csho2mgkegta.us-east-1.rds.amazonaws.com` |
| **Host (via Proxy)** | `localhost` |
| **Port (External)** | `5432` |
| **Port (via Proxy)** | `5433` |
| **Database** | `aifinancedb` |
| **Username** | `postgres` |
| **Password** | `AiFinance123!` |

---

## 🗄️ Database Schema

### Tables Created:

1. **User** (auth-service)
   - `id` (UUID, Primary Key)
   - `email` (Unique)
   - `passwordHash`
   - `createdAt`

2. **Upload** (upload-service)
   - `id` (UUID, Primary Key)
   - `userId`
   - `fileName`
   - `fileSize`
   - `fileHash` (Unique)
   - `status` (UPLOADED, PROCESSING, DONE, FAILED)
   - `createdAt`

3. **Transaction** (analytics-service)
   - `id` (UUID, Primary Key)
   - `userId`
   - `description`
   - `amount`
   - `category`
   - `date`
   - Various other transaction fields

---

## 🚨 Troubleshooting

### "Too many pods" error
Your t3.small node is at capacity. Scale down a service temporarily:
```powershell
kubectl scale deployment parser-worker --replicas=0 -n ai-finance
# ... do your database work ...
kubectl scale deployment parser-worker --replicas=1 -n ai-finance
```

### Connection refused
Make sure the proxy pod is running:
```powershell
kubectl get pods -n ai-finance -l app=db-proxy-temp
kubectl logs db-proxy-temp -n ai-finance
```

### Can't connect from pgAdmin4
1. Ensure the port-forward script is still running
2. Check `localhost:5433` is not blocked by firewall
3. Try Option 3 (psql) to verify database is accessible

---

## 📚 Useful SQL Queries

```sql
-- See all tables and row counts
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Recent users
SELECT id, email, "createdAt" 
FROM "User" 
ORDER BY "createdAt" DESC 
LIMIT 10;

-- Upload statistics
SELECT 
    status, 
    COUNT(*) as count,
    SUM("fileSize") as total_bytes
FROM "Upload"
GROUP BY status;

-- Transaction summary by category
SELECT 
    category,
    COUNT(*) as count,
    SUM(amount) as total
FROM "Transaction"
GROUP BY category
ORDER BY total DESC;
```

---

## 🔗 Related Resources

- **Check Database**: `.\scripts\check-database.ps1`
- **Service URLs**: See main README for API endpoints
- **Secrets**: `infra/kubernetes/configmaps/secrets-dev.yaml`
- **Database Migrations**: `apps/*/prisma/migrations/`
