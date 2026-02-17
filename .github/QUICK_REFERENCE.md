# CI/CD Quick Reference

Quick commands and workflows for daily development tasks.

## 🚀 Common Tasks

### Deploy to Production

```bash
# Merge PR to main
git checkout main
git pull
# → Auto-deploys via CD workflow

# Or manual deploy
gh workflow run cd.yml -f service=all -f environment=dev
```

### Check Workflow Status

```bash
# List recent runs
gh run list --limit 10

# Watch current run
gh run watch

# View specific run
gh run view <run-id> --log
```

### Rollback a Service

```bash
# Via GitHub CLI
gh workflow run rollback.yml -f service=auth-service -f image_tag=abc1234

# Or via Web UI
# Actions → Rollback Deployment → Run workflow
```

### Run Database Migrations

```bash
# Deploy migrations
gh workflow run database-migrations.yml \
  -f service=auth-service \
  -f action=deploy \
  -f environment=dev

# Check status
gh workflow run database-migrations.yml \
  -f service=all \
  -f action=status \
  -f environment=dev
```

### Manage Secrets

```bash
# List secrets
gh secret list

# Set secret (interactive)
.\.github\scripts\setup-secrets.ps1

# Set secret (command)
echo "value" | gh secret set SECRET_NAME

# Delete secret
gh secret delete SECRET_NAME
```

## 📊 Check Deployment Status

```bash
# Via kubectl
kubectl get pods -n ai-finance
kubectl get svc -n ai-finance
kubectl logs -l app=auth-service -n ai-finance --tail=50

# Via AWS CLI
aws eks describe-cluster --name ai-finance-eks-dev --region us-east-1
aws ecr describe-repositories --region us-east-1

# Service URLs
kubectl get svc -n ai-finance -o wide | grep LoadBalancer
```

## 🔧 Local Testing

```bash
# Test Docker build locally
docker build -f infra/docker/auth-service.Dockerfile -t auth-service:test .

# Test Kubernetes manifests
kubectl apply --dry-run=client -f infra/kubernetes/deployments/auth-service.yaml

# Test Terraform changes
cd infra/terraform
terraform plan
```

## 🐛 Debug Failed Workflow

```bash
# View logs
gh run view --log

# Re-run failed jobs
gh run rerun <run-id>

# Re-run only failed jobs
gh run rerun <run-id> --failed
```

## 📋 Workflow Triggers

| Workflow | Auto Trigger | Manual | When |
|----------|--------------|--------|------|
| CI | ✅ PR, Push to develop/feature | ✅ | Code changes |
| CD | ✅ Push to main | ✅ | Deploy services |
| Terraform | ✅ PR/Push (infra changes) | ✅ | Infrastructure |
| Migrations | ❌ | ✅ Only | Database updates |
| Rollback | ❌ | ✅ Only | Emergency |
| ECR Cleanup | ✅ Weekly (Sunday 2 AM) | ✅ | Image cleanup |

## 🔐 Required Secrets

```bash
AWS_ACCESS_KEY_ID       # AWS access key
AWS_SECRET_ACCESS_KEY   # AWS secret key
DATABASE_URL            # PostgreSQL connection
JWT_SECRET              # JWT signing key
OPENAI_API_KEY          # OpenAI API key (optional)
```

## 📈 Monitoring

```bash
# GitHub Actions dashboard
https://github.com/<owner>/<repo>/actions

# AWS CloudWatch logs
aws logs tail /aws/eks/ai-finance-eks-dev/cluster --follow

# Kubernetes dashboard (if installed)
kubectl proxy
# Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## 🎯 Best Practices

1. **Always create PR**: Don't push directly to main
2. **Wait for CI**: Ensure all checks pass before merge
3. **Review Terraform plans**: Always review plan output in PRs
4. **Test migrations locally**: Before running in production
5. **Monitor deployments**: Watch logs during deployment
6. **Use feature flags**: For gradual rollouts
7. **Tag releases**: Use semantic versioning
8. **Document changes**: Update README for major changes

## 🆘 Emergency Procedures

### Service is Down

```bash
# 1. Check pod status
kubectl get pods -n ai-finance

# 2. View recent logs
kubectl logs -l app=<service> -n ai-finance --tail=100

# 3. Restart deployment
kubectl rollout restart deployment/<service> -n ai-finance

# 4. If still failing, rollback
gh workflow run rollback.yml -f service=<service>
```

### Failed Deployment

```bash
# 1. Check workflow logs
gh run view --log

# 2. Check pod events
kubectl describe pod <pod-name> -n ai-finance

# 3. Rollback to previous version
gh workflow run rollback.yml -f service=all

# 4. Fix issue and redeploy
git revert <bad-commit>
git push origin main
```

### Database Migration Failed

```bash
# 1. Check migration status
gh workflow run database-migrations.yml -f action=status

# 2. Check pod logs
kubectl logs -l app=<service> -n ai-finance | grep migration

# 3. Mark migration as applied (if safe)
kubectl exec deployment/<service> -n ai-finance -- \
  npx prisma migrate resolve --applied <migration> \
  --schema=/app/apps/<service>/prisma/schema.prisma

# 4. Or reset (⚠️ data loss!)
gh workflow run database-migrations.yml -f action=reset -f service=<service>
```

## 📞 Support

- **CI/CD Issues**: Check [Full Documentation](.github/README.md)
- **AWS Issues**: Review [AWS Console](https://console.aws.amazon.com/)
- **Kubernetes Issues**: Check `kubectl` logs and events
- **General Questions**: Open GitHub issue

---

**Last Updated**: February 17, 2026
