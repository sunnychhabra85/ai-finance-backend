# CI/CD Pipeline Documentation

Complete GitHub Actions CI/CD pipeline for AI Finance Backend microservices deployed to AWS EKS.

## 📋 Table of Contents

- [Overview](#overview)
- [Workflows](#workflows)
- [Setup Instructions](#setup-instructions)
- [GitHub Secrets](#github-secrets)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This CI/CD pipeline provides automated:
- **Continuous Integration**: Build, test, and validate code changes
- **Continuous Deployment**: Deploy to AWS EKS automatically on main branch
- **Database Migrations**: Manage Prisma migrations across services
- **Infrastructure as Code**: Terraform validation and deployment
- **Rollback Capability**: Quick rollback to previous versions
- **Image Cleanup**: Automated ECR image lifecycle management

### Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   GitHub    │────▶│ GitHub       │────▶│   AWS EKS   │
│ Repository  │     │ Actions      │     │  Cluster    │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   AWS ECR    │
                    │ (Images)     │
                    └──────────────┘
```

## 🔄 Workflows

### 1. CI - Build and Test ([ci.yml](.github/workflows/ci.yml))

**Triggers:**
- Pull requests to `main` or `develop`
- Pushes to `develop` or `feature/**` branches
- Manual dispatch

**What it does:**
- Detects which services changed using path filters
- Runs builds only for affected services
- Executes linting and tests
- Builds Docker images (without pushing)
- Validates all changes before merge

**Example:**
```yaml
# Automatically runs on PR
- Edit apps/auth-service/src/app.module.ts
- Create PR → CI runs only for auth-service
- All checks pass → Ready to merge
```

### 2. CD - Deploy to AWS ([cd.yml](.github/workflows/cd.yml))

**Triggers:**
- Push to `main` branch (auto-deploy)
- Manual dispatch (choose service and environment)

**What it does:**
1. Detects changed services
2. Builds Docker images with tags (latest, git SHA, timestamp)
3. Pushes images to AWS ECR
4. Updates Kubernetes deployments
5. Restarts affected services
6. Runs health checks
7. Sends deployment notifications

**Deployment Strategy:**
- **Rolling updates**: Zero-downtime deployments
- **Health checks**: Ensures pods are ready before completion
- **Automatic rollback**: On deployment failure

**Manual Deployment:**
```bash
# Deploy specific service to dev
Actions → CD - Deploy to AWS EKS → Run workflow
  Environment: dev
  Service: auth-service
```

### 3. Terraform - Infrastructure ([terraform.yml](.github/workflows/terraform.yml))

**Triggers:**
- Changes to `infra/terraform/**`
- Manual dispatch

**What it does:**
- **Validate**: Checks Terraform formatting and syntax
- **Plan**: Shows infrastructure changes in PR comments
- **Apply**: Applies changes on merge to main (requires approval)
- **Destroy**: Manual destruction with environment protection

**Workflow:**
```
PR with Terraform changes
  ↓
terraform validate + plan
  ↓
Plan posted as PR comment
  ↓
Merge to main
  ↓
terraform apply (with approval)
```

### 4. Database Migrations ([database-migrations.yml](.github/workflows/database-migrations.yml))

**Triggers:** Manual dispatch only

**What it does:**
- Runs Prisma migrations in production pods
- Supports: deploy, status, reset
- Can target specific service or all services

**Usage:**
```bash
Actions → Database Migrations → Run workflow
  Service: auth-service
  Action: deploy
  Environment: dev
```

### 5. Rollback Deployment ([rollback.yml](.github/workflows/rollback.yml))

**Triggers:** Manual dispatch only

**What it does:**
- Rolls back to previous deployment
- OR rolls back to specific image tag
- Waits for pods to be healthy
- Shows logs on failure

**Usage:**
```bash
# Rollback to previous version
Actions → Rollback Deployment → Run workflow
  Service: upload-service
  Image tag: (leave empty)

# Rollback to specific version
Actions → Rollback Deployment → Run workflow
  Service: analytics-service
  Image tag: abc1234
```

### 6. ECR Cleanup ([ecr-cleanup.yml](.github/workflows/ecr-cleanup.yml))

**Triggers:**
- Scheduled: Every Sunday at 2 AM UTC
- Manual dispatch

**What it does:**
- Keeps latest N images per service (default: 10)
- Deletes untagged images
- Reduces ECR storage costs

**Configuration:**
```bash
Actions → ECR Image Cleanup → Run workflow
  Keep count: 15  # Keep latest 15 images
```

## 🚀 Setup Instructions

### Prerequisites

1. **GitHub Repository**: Fork or clone this repository
2. **AWS Account**: With EKS cluster deployed
3. **GitHub CLI** (optional): For easier secret management
   ```bash
   winget install GitHub.cli
   gh auth login
   ```

### Step 1: Configure GitHub Secrets

Run the automated setup script:

```powershell
# From repository root
.\.github\scripts\setup-secrets.ps1
```

Or manually set secrets in GitHub:
```
Repository → Settings → Secrets and variables → Actions → New repository secret
```

### Step 2: Update Workflow Variables

Edit [cd.yml](.github/workflows/cd.yml) and [terraform.yml](.github/workflows/terraform.yml):

```yaml
env:
  AWS_REGION: us-east-1              # Your AWS region
  EKS_CLUSTER_NAME: ai-finance-eks-dev  # Your EKS cluster name
  ECR_REGISTRY: YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
  K8S_NAMESPACE: ai-finance
```

### Step 3: Enable Workflows

```
Repository → Actions → Enable workflows
```

### Step 4: Test the Pipeline

```bash
# Create feature branch
git checkout -b feature/test-ci-cd

# Make a small change
echo "# CI/CD Test" >> README.md

# Push and create PR
git add .
git commit -m "test: CI/CD pipeline"
git push origin feature/test-ci-cd

# Open PR on GitHub → Watch CI workflow run
```

## 🔐 GitHub Secrets

| Secret Name | Description | Required | Example |
|-------------|-------------|----------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment | ✅ Yes | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key | ✅ Yes | `wJalrXUt...` |
| `DATABASE_URL` | PostgreSQL connection string | ✅ Yes | `postgresql://user:pass@host:5432/db` |
| `JWT_SECRET` | JWT signing secret (min 32 chars) | ✅ Yes | `your-super-secret-jwt-key` |
| `OPENAI_API_KEY` | OpenAI API key for AI service | ⚠️ Optional | `sk-...` |

### Setting Secrets via CLI

```bash
# List current secrets
gh secret list

# Set a secret
echo "your-secret-value" | gh secret set SECRET_NAME

# Set from file
gh secret set AWS_SECRET_ACCESS_KEY < aws-secret.txt

# Interactive setup (recommended)
.\.github\scripts\setup-secrets.ps1
```

### Getting Required Values

```bash
# AWS credentials (from IAM user with EKS access)
# Create in AWS Console: IAM → Users → Create user → Attach policies

# DATABASE_URL (from Terraform output)
cd infra/terraform
terraform output rds_connection_string

# JWT_SECRET (generate random)
openssl rand -base64 32

# OPENAI_API_KEY (from OpenAI dashboard)
# https://platform.openai.com/api-keys
```

## 📖 Usage

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/add-new-endpoint

# 2. Make changes
# Edit code...

# 3. Commit and push
git add .
git commit -m "feat: add new endpoint"
git push origin feature/add-new-endpoint

# 4. Create PR
# → CI workflow runs automatically
# → Docker build test validates containers
# → All checks must pass

# 5. Merge to main
# → CD workflow deploys automatically
# → Only changed services are deployed
```

### Deploying Specific Service

```bash
# Go to GitHub Actions
Actions → CD - Deploy to AWS EKS → Run workflow

# Select options:
Environment: dev
Service: auth-service  # or 'all' for everything
```

### Running Migrations

```bash
# Deploy migrations
Actions → Database Migrations → Run workflow
  Service: auth-service
  Action: deploy
  Environment: dev

# Check migration status
Actions → Database Migrations → Run workflow
  Service: all
  Action: status
  Environment: dev
```

### Rolling Back

```bash
# Get available image tags
aws ecr describe-images \
  --repository-name auth-service \
  --query 'imageDetails[*].[imageTags[0],imagePushedAt]' \
  --output table

# Rollback to specific version
Actions → Rollback Deployment → Run workflow
  Service: auth-service
  Image tag: abc1234

# Or rollback to previous
Actions → Rollback Deployment → Run workflow
  Service: auth-service
  Image tag: (leave empty)
```

### Infrastructure Changes

```bash
# 1. Edit Terraform files
cd infra/terraform
# Edit *.tf files...

# 2. Create PR
git checkout -b infra/update-rds
git add infra/terraform/
git commit -m "infra: update RDS instance size"
git push

# 3. Open PR
# → Terraform workflow runs
# → Plan is posted as comment
# → Review changes

# 4. Merge to main
# → Requires manual approval
# → terraform apply runs automatically
```

## 🔍 Monitoring

### View Workflow Status

```bash
# Via GitHub CLI
gh run list
gh run view <run-id>
gh run watch  # Watch latest run

# Via Web UI
Repository → Actions → Select workflow
```

### Check Deployment Status

```bash
# Get pod status
kubectl get pods -n ai-finance

# Get deployment status
kubectl get deployments -n ai-finance

# View service URLs
kubectl get svc -n ai-finance -o wide

# Check logs
kubectl logs -l app=auth-service -n ai-finance --tail=100
```

### Health Check Endpoints

```bash
# Get service URLs
kubectl get svc -n ai-finance | grep LoadBalancer

# Test endpoints
curl http://<auth-lb-url>/api/auth/health
curl http://<upload-lb-url>/api/upload/health
curl http://<analytics-lb-url>/api/analytics/health
```

## 🐛 Troubleshooting

### CI Workflow Fails

**Issue**: Build fails with "npm ci failed"
```bash
Solution:
1. Delete package-lock.json
2. Run npm install locally
3. Commit new package-lock.json
```

**Issue**: Docker build fails
```bash
Solution:
1. Test locally: docker build -f infra/docker/auth-service.Dockerfile .
2. Check Dockerfile paths
3. Verify all dependencies are in package.json
```

### CD Workflow Fails

**Issue**: AWS authentication fails
```bash
Solution:
1. Verify secrets: gh secret list
2. Check IAM permissions for the access key
3. Required policies: EKS, ECR, EC2 (describe operations)
```

**Issue**: Deployment timeout
```bash
Solution:
1. Check pod status: kubectl get pods -n ai-finance
2. View logs: kubectl logs <pod-name> -n ai-finance
3. Common issues:
   - Image pull errors (wrong ECR URL)
   - Database connection issues (wrong DATABASE_URL)
   - Resource limits (insufficient node capacity)
```

**Issue**: Rollout stuck
```bash
Solution:
1. Check pod events: kubectl describe pod <pod-name> -n ai-finance
2. Check deployment: kubectl rollout status deployment/<service> -n ai-finance
3. Force restart: kubectl rollout restart deployment/<service> -n ai-finance
```

### Terraform Workflow Fails

**Issue**: State lock error
```bash
Solution:
# Force unlock (use carefully!)
cd infra/terraform
terraform force-unlock <lock-id>
```

**Issue**: Provider authentication fails
```bash
Solution:
1. Ensure AWS secrets are set correctly
2. Check IAM permissions (AdministratorAccess for full Terraform)
3. Verify region matches: AWS_REGION in workflow
```

### Migration Workflow Fails

**Issue**: "Migration already exists"
```bash
Solution:
# Check migration status
Actions → Database Migrations
  Action: status

# If needed, resolve manually
kubectl exec -it deployment/auth-service -n ai-finance -- \
  npx prisma migrate resolve --applied <migration-name> \
  --schema=/app/apps/auth-service/prisma/schema.prisma
```

### ECR Cleanup Issues

**Issue**: "Repository not found"
```bash
Solution:
1. Verify ECR repositories exist
2. Check repository names match service names
3. Ensure AWS credentials have ECR permissions
```

## 📊 Workflow Optimization

### Reduce CI Time

```yaml
# Use cache effectively
- uses: actions/setup-node@v4
  with:
    cache: 'npm'  # Cache node_modules

# Run jobs in parallel
strategy:
  matrix:
    service: [auth, upload, analytics]
```

### Reduce Deployment Time

```yaml
# Deploy only changed services
if: needs.detect-changes.outputs.auth-service == 'true'

# Parallel builds
strategy:
  matrix:
    service: [...]  # Builds run concurrently
```

### Reduce Costs

```yaml
# ECR cleanup - keep fewer images
keep_count: 5  # Instead of 10

# Use self-hosted runners (if available)
runs-on: self-hosted
```

## 🔧 Advanced Configuration

### Multi-Environment Setup

```yaml
# Create environment-specific secrets
# Settings → Environments → New environment

# dev, staging, prod environments
environment:
  name: ${{ github.event.inputs.environment }}
  url: https://api-${{ github.event.inputs.environment }}.example.com
```

### Slack Notifications

```yaml
# Add to cd.yml notify job
- name: Slack notification
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Deployment ${{ job.status }}: ${{ github.repository }}"
      }
```

### Custom Health Checks

```yaml
# Add to cd.yml after deployment
- name: Custom health check
  run: |
    for i in {1..30}; do
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_URL/health)
      if [ "$STATUS" == "200" ]; then
        echo "Service healthy"
        exit 0
      fi
      sleep 10
    done
    exit 1
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Prisma Migrations](https://www.prisma.io/docs/concepts/components/prisma-migrate)

## 🤝 Contributing

When contributing, ensure:
- [ ] CI workflow passes
- [ ] Terraform plan is reviewed
- [ ] Database migrations are tested locally
- [ ] Rollback procedure is documented

## 📝 License

Same as repository license.

---

**Need Help?** Open an issue or contact the DevOps team.
