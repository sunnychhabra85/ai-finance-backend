# Terraform AWS Infrastructure

This folder contains Terraform code to provision the complete AWS infrastructure for AI Finance Backend.

## Architecture

```
┌─────────────────────────────────────────┐
│         AWS Region (us-east-1)          │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │      VPC (10.0.0.0/16)            │  │
│  │  ┌────────────┐  ┌────────────┐   │  │
│  │  │  Public    │  │  Private   │   │  │
│  │  │  Subnets   │  │  Subnets   │   │  │
│  │  │ (ALB, NAT) │  │ (EKS, RDS) │   │  │
│  │  └────────────┘  └────────────┘   │  │
│  │                                   │  │
│  │  ┌────────────────────────────┐   │  │
│  │  │   EKS Cluster              │   │  │
│  │  │  ┌──────────────────────┐  │   │  │
│  │  │  │  Worker Nodes (3)    │  │   │  │
│  │  │  │  - t3.medium         │  │   │  │
│  │  │  │  - Auto-scaling      │  │   │  │
│  │  │  └──────────────────────┘  │   │  │
│  │  └────────────────────────────┘   │  │
│  │                                   │  │
│  │  ┌──────────────┐  ┌──────────┐   │  │
│  │  │  RDS Postgres│  │  S3 Bucket   │  │
│  │  │  - db.t3micro│  │  - Uploads   │  │
│  │  │  - 20GB      │  │  - Versioned │  │
│  │  └──────────────┘  └──────────┘   │  │
│  │                                   │  │
│  │  ┌──────────────────────────┐     │  │
│  │  │  ECR Registries          │     │  │
│  │  │  - 5 service repos       │     │  │
│  │  └──────────────────────────┘     │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  CloudWatch Logs & Monitoring     │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Prerequisites

- AWS Account
- Terraform >= 1.0
- AWS CLI configured
- kubectl

## Setup

### 1. Initialize Terraform

```bash
cd infra/terraform

# Initialize working directory
terraform init

# Validate configuration
terraform validate
```

### 2. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Important values to change:**
- `database_password` - Use a strong, secure password
- `environment` - dev, staging, or prod
- `aws_region` - Your preferred region

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output to see what resources will be created.

### 4. Apply Configuration

```bash
terraform apply tfplan
```

This will create:
- VPC with public/private subnets
- EKS cluster with 3 worker nodes
- RDS PostgreSQL database
- S3 buckets for file uploads
- ECR registries for Docker images
- CloudWatch logs and monitoring
- IAM roles and policies
- Security groups

**Estimated time: 20-30 minutes**

### 5. Configure kubectl

```bash
# Get the command from output
aws eks update-kubeconfig --name ai-finance-eks-dev --region us-east-1

# Verify connection
kubectl get nodes
```

## Deployment

### 1. Push Docker Images to ECR

```bash
# Get ECR repositories from terraform output
terraform output ecr_repositories

# Build and push images
for service in auth-service upload-service parser-worker analytics-service ai-service; do
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
  
  docker build -f infra/docker/${service}.Dockerfile -t ai-finance/${service}:latest .
  
  docker tag ai-finance/${service}:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ai-finance/${service}:latest
  
  docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ai-finance/${service}:latest
done
```

### 2. Update Kubernetes Manifests

Update image references in `infra/kubernetes/deployments/`:

```yaml
image: YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ai-finance/auth-service:latest
```

### 3. Deploy to EKS

```bash
cd ../kubernetes
./deploy.sh dev
```

### 4. Verify Deployment

```bash
kubectl get pods -n ai-finance
kubectl get svc -n ai-finance
kubectl get ingress -n ai-finance
```

## Costs

Estimated monthly costs (dev environment):

- EKS: ~$72 (cluster fee)
- EC2 (3x t3.medium): ~$30/month
- RDS (db.t3.micro): ~$30/month
- S3: ~$1-5/month
- Data transfer: ~$10-50/month

**Total: ~$150-200/month for dev**

Costs scale with prod (Multi-AZ RDS, more nodes).

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm when prompted
```

**Note:** This will delete ALL resources including databases. Make sure you have backups!

## Troubleshooting

### EKS nodes not starting

```bash
# Check node logs
kubectl get nodes
kubectl describe nodes

# Check EC2 instances
aws ec2 describe-instances
```

### RDS not accessible from EKS

```bash
# Check security groups
aws ec2 describe-security-groups

# Test connectivity
kubectl run -it --rm debug --image=postgres:16-alpine --restart=Never -- psql -h <rds-endpoint> -U postgres
```

### Images not pulling

```bash
# Check ECR permissions
aws iam get-user

# Verify image exists
aws ecr describe-images --repository-name ai-finance/auth-service
```

## More Information

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform State Management](https://www.terraform.io/docs/language/state/)