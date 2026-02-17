# CI/CD Setup Checklist

Complete this checklist to set up the CI/CD pipeline.

## ✅ Prerequisites

- [ ] GitHub repository created and code pushed
- [ ] AWS account with necessary permissions
- [ ] EKS cluster deployed (via Terraform)
- [ ] ECR repositories created for all services
- [ ] GitHub CLI installed (optional, for easier setup)

## 🔐 Step 1: Configure Secrets

### Required Secrets

- [ ] `AWS_ACCESS_KEY_ID` - AWS access key for deployments
- [ ] `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- [ ] `DATABASE_URL` - PostgreSQL connection string
- [ ] `JWT_SECRET` - JWT signing secret (min 32 characters)

### Optional Secrets

- [ ] `OPENAI_API_KEY` - For AI service functionality

### Setup Methods

**Option A: Automated (Recommended)**
```powershell
# Windows PowerShell
.\.github\scripts\setup-secrets.ps1

# Linux/Mac
chmod +x .github/scripts/setup-secrets.sh
./.github/scripts/setup-secrets.sh
```

**Option B: Manual**
```bash
# Via GitHub CLI
echo "your-value" | gh secret set SECRET_NAME

# Via Web UI
# Repository → Settings → Secrets and variables → Actions
```

**Option C: GitHub Web UI**
1. Go to repository Settings
2. Navigate to Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret one by one

## ⚙️ Step 2: Update Workflow Configuration

Edit [.github/workflows/cd.yml](.github/workflows/cd.yml):

```yaml
env:
  AWS_REGION: us-east-1              # ✏️ Update to your region
  EKS_CLUSTER_NAME: ai-finance-eks-dev  # ✏️ Update to your cluster name
  ECR_REGISTRY: 014071048720.dkr.ecr.us-east-1.amazonaws.com  # ✏️ Update account ID
  K8S_NAMESPACE: ai-finance           # ✏️ Update if different
```

Edit [.github/workflows/terraform.yml](.github/workflows/terraform.yml):

```yaml
env:
  AWS_REGION: us-east-1              # ✏️ Update to your region
  TF_VERSION: 1.10.5                 # ✏️ Update if using different version
```

- [ ] AWS_REGION updated
- [ ] EKS_CLUSTER_NAME updated
- [ ] ECR_REGISTRY updated (with correct account ID)
- [ ] K8S_NAMESPACE verified
- [ ] TF_VERSION matches your Terraform version

## 🚀 Step 3: Enable Workflows

- [ ] Enable GitHub Actions in repository settings
- [ ] Review workflow files in `.github/workflows/`
- [ ] Commit any configuration changes

```bash
git add .github/workflows/
git commit -m "chore: configure CI/CD workflows"
git push origin main
```

## 🧪 Step 4: Test the Pipeline

### Test CI Workflow

- [ ] Create feature branch
  ```bash
  git checkout -b feature/test-cicd
  ```

- [ ] Make a small change
  ```bash
  echo "# CI/CD Test" >> README.md
  git add README.md
  git commit -m "test: CI/CD pipeline"
  git push origin feature/test-cicd
  ```

- [ ] Create Pull Request on GitHub
- [ ] Verify CI workflow runs and passes
- [ ] Review workflow logs in Actions tab

### Test CD Workflow

- [ ] Merge the test PR to main
- [ ] Verify CD workflow triggers automatically
- [ ] Monitor deployment progress in Actions tab
- [ ] Check services are updated in Kubernetes
  ```bash
  kubectl get pods -n ai-finance
  kubectl get deployments -n ai-finance
  ```

### Test Manual Deployment

- [ ] Go to Actions → CD - Deploy to AWS EKS
- [ ] Click "Run workflow"
- [ ] Select service and environment
- [ ] Monitor deployment

## 📊 Step 5: Verify Deployment

- [ ] All pods are running
  ```bash
  kubectl get pods -n ai-finance
  ```

- [ ] Services have external IPs
  ```bash
  kubectl get svc -n ai-finance
  ```

- [ ] Health checks pass
  ```bash
  # Get service URL
  AUTH_URL=$(kubectl get svc auth-service -n ai-finance -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  
  # Test endpoint
  curl http://$AUTH_URL/api/auth/register -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"Test123!"}'
  ```

- [ ] Database tables exist
  ```bash
  .\scripts\check-database.ps1 -Table all
  ```

## 🔄 Step 6: Test Additional Workflows

### Database Migrations

- [ ] Run migration workflow
  ```bash
  gh workflow run database-migrations.yml \
    -f service=auth-service \
    -f action=status \
    -f environment=dev
  ```

### Rollback

- [ ] Test rollback workflow (optional)
  ```bash
  gh workflow run rollback.yml \
    -f service=auth-service
  ```

### ECR Cleanup

- [ ] Run cleanup workflow (optional)
  ```bash
  gh workflow run ecr-cleanup.yml \
    -f keep_count=10
  ```

## 📚 Step 7: Documentation

- [ ] Review [CI/CD README](.github/README.md)
- [ ] Bookmark [Quick Reference](.github/QUICK_REFERENCE.md)
- [ ] Share documentation with team
- [ ] Add workflow status badges to main README (optional)

## 🎯 Optional: Advanced Setup

### Environment Protection Rules

- [ ] Create production environment in GitHub
  ```
  Settings → Environments → New environment → "production"
  ```
- [ ] Add required reviewers
- [ ] Set deployment branch to `main` only

### Notifications

- [ ] Set up Slack webhook (if desired)
- [ ] Add `SLACK_WEBHOOK` secret
- [ ] Update workflows to send notifications

### Monitoring

- [ ] Set up AWS CloudWatch alarms
- [ ] Configure log aggregation
- [ ] Set up Kubernetes metrics

### Status Badges

Add to main README.md:

```markdown
![CI](https://github.com/YOUR_ORG/YOUR_REPO/workflows/CI%20-%20Build%20and%20Test/badge.svg)
![CD](https://github.com/YOUR_ORG/YOUR_REPO/workflows/CD%20-%20Deploy%20to%20AWS%20EKS/badge.svg)
![Terraform](https://github.com/YOUR_ORG/YOUR_REPO/workflows/Terraform%20-%20Infrastructure/badge.svg)
```

## ✅ Final Verification

- [ ] All workflows are enabled
- [ ] All secrets are configured
- [ ] CI workflow passes on PR
- [ ] CD workflow deploys successfully
- [ ] Services are accessible
- [ ] Database migrations work
- [ ] Rollback procedure tested
- [ ] Team is trained on workflows
- [ ] Documentation is accessible

## 🎉 Completion

Once all items are checked, your CI/CD pipeline is fully configured!

**Next Steps:**
1. Start using feature branches for development
2. Monitor workflows in the Actions tab
3. Review deployment logs regularly
4. Update documentation as needed

---

**Need Help?**
- Review full documentation: [.github/README.md](.github/README.md)
- Quick commands: [.github/QUICK_REFERENCE.md](.github/QUICK_REFERENCE.md)
- Open GitHub issue for questions
