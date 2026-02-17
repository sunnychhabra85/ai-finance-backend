# AI Finance Backend - Microservices

Complete microservices architecture for AI-powered finance tracking application deployed on AWS EKS.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (EKS)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐         │
│  │ Auth Service│  │Upload Service│  │Analytics Svc  │         │
│  │  (NestJS)   │  │  (NestJS)    │  │  (NestJS)     │         │
│  └─────────────┘  └──────────────┘  └───────────────┘         │
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐                            │
│  │ AI Service  │  │Parser Worker │                            │
│  │  (NestJS)   │  │  (NestJS)    │                            │
│  └─────────────┘  └──────────────┘                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                         │
│  • RDS PostgreSQL  • S3 Bucket  • ECR Registry  • VPC         │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Services

| Service | Purpose | Port | Tech Stack |
|---------|---------|------|------------|
| **auth-service** | User authentication & authorization | 3001 | NestJS, Prisma, JWT |
| **upload-service** | File upload & storage management | 3002 | NestJS, Prisma, S3 |
| **analytics-service** | Transaction analytics & insights | 3003 | NestJS, Prisma |
| **ai-service** | AI-powered chat & recommendations | 3004 | NestJS, OpenAI |
| **parser-worker** | Background file parsing | - | NestJS |

## 🚀 Quick Start

### Prerequisites
- Node.js 20.x
- Docker & Docker Compose
- AWS Account (for production deployment)
- PostgreSQL 15+ (for local development)

### Local Development

```bash
# Install dependencies
npm install

# Start all services with Docker Compose
docker-compose up

# Or run individual services
npm run auth-service
npm run upload-service
npm run analytics-service
npm run ai-chat-service
npm run parser-worker
```

### Database Setup

```bash
# Generate Prisma clients
npm run auth:generate
npm run upload:generate
npm run analytics:generate

# Run migrations
npm run auth:migrate
npm run upload:migrate
npm run analytics:migrate

# Open Prisma Studio (optional)
npm run auth:studio
```

## ☁️ Production Deployment

### Infrastructure (AWS)

```bash
# Deploy infrastructure with Terraform
cd infra/terraform
terraform init
terraform plan
terraform apply

# Deploy services to Kubernetes
cd ../kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmaps/
kubectl apply -f secrets/
kubectl apply -f deployments/
kubectl apply -f services/
```

### CI/CD Pipeline

Complete GitHub Actions CI/CD pipeline for automated deployments.

**📚 [CI/CD Documentation](.github/README.md)**

```bash
# Setup secrets
.\.github\scripts\setup-secrets.ps1

# Test CI/CD
git checkout -b feature/test
git push origin feature/test
# → CI runs automatically

# Deploy to production  
git checkout main
git merge feature/test
git push origin main
# → CD deploys automatically
```

**Quick Reference:**
- 📖 [Full CI/CD Guide](.github/README.md)
- ⚡ [Quick Reference](.github/QUICK_REFERENCE.md)
- ✅ [Setup Checklist](.github/SETUP_CHECKLIST.md)

## 📊 Infrastructure Management

```powershell
# Check infrastructure status
.\scripts\check-infrastructure.ps1

# Stop infrastructure (save costs)
.\scripts\stop-infrastructure.ps1

# Start infrastructure
.\scripts\start-infrastructure.ps1

# Check database
.\scripts\check-database.ps1 -Table all
```

**Cost Savings:**
- Running: ~$46/month
- Stopped: ~$2/month
- Data preserved when stopped

## 🗄️ Database Schema

### Auth Service
- **User**: User accounts with authentication

### Upload Service
- **Upload**: File metadata and S3 references

### Analytics Service
- **Transaction**: Financial transactions with categorization

**📚 [Database Connection Guide](DATABASE_CONNECTION.md)**

## 🔑 Environment Variables

### Required for All Services
```env
DATABASE_URL=postgresql://user:password@host:5432/database
JWT_SECRET=your-secret-key-min-32-characters
NODE_ENV=development
```

### Service-Specific

**upload-service:**
```env
AWS_BUCKET_NAME=ai-finance-uploads
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
```

**ai-service:**
```env
OPENAI_API_KEY=sk-...
```

## 🧪 Testing

```bash
# Run tests for all services
npm test

# Run tests for specific service
cd apps/auth-service
npm test
```

## 📝 API Documentation

Once services are running, access Swagger documentation:

- Auth Service: `http://localhost:3001/api`
- Upload Service: `http://localhost:3002/api`
- Analytics Service: `http://localhost:3003/api`
- AI Service: `http://localhost:3004/api`

Or in production:
```bash
# Get service URLs
kubectl get svc -n ai-finance | grep LoadBalancer
```

## 🗂️ Project Structure

```
ai-finance-backend/
├── apps/                      # Microservices
│   ├── auth-service/         # Authentication service
│   ├── upload-service/       # File upload service
│   ├── analytics-service/    # Analytics service
│   ├── ai-service/          # AI chat service
│   └── parser-worker/       # Background worker
├── packages/                 # Shared packages
│   ├── shared-types/        # TypeScript types
│   └── shared-utils/        # Utility functions
├── infra/                   # Infrastructure
│   ├── terraform/           # AWS infrastructure (IaC)
│   ├── kubernetes/          # K8s manifests
│   ├── docker/              # Dockerfiles
│   ├── helm/               # Helm charts (future)
│   └── monitoring/         # Monitoring configs
├── scripts/                 # Utility scripts
│   ├── check-infrastructure.ps1
│   ├── stop-infrastructure.ps1
│   ├── start-infrastructure.ps1
│   └── check-database.ps1
├── .github/                 # GitHub Actions
│   ├── workflows/          # CI/CD workflows
│   ├── scripts/           # Setup scripts
│   └── README.md          # CI/CD documentation
└── package.json            # Root package.json (workspace)
```

## 🛠️ Tech Stack

### Backend
- **Framework**: NestJS
- **Language**: TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT with Passport
- **File Storage**: AWS S3
- **AI**: OpenAI GPT

### Infrastructure
- **Orchestration**: Kubernetes (AWS EKS)
- **Container Registry**: AWS ECR
- **Infrastructure as Code**: Terraform
- **Database**: AWS RDS PostgreSQL
- **Load Balancing**: AWS Application Load Balancer
- **CI/CD**: GitHub Actions

### DevOps
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch (planned: Prometheus + Grafana)
- **Logging**: CloudWatch Logs

## 📚 Documentation

| Topic | Document |
|-------|----------|
| **CI/CD Pipeline** | [.github/README.md](.github/README.md) |
| **Quick Commands** | [.github/QUICK_REFERENCE.md](.github/QUICK_REFERENCE.md) |
| **Setup Checklist** | [.github/SETUP_CHECKLIST.md](.github/SETUP_CHECKLIST.md) |
| **Database Access** | [DATABASE_CONNECTION.md](DATABASE_CONNECTION.md) |
| **Terraform** | [infra/terraform/README.md](infra/terraform/README.md) |
| **Docker Compose** | [infra/docker-compose/README.md](infra/docker-compose/README.md) |

## 🔒 Security

- JWT-based authentication
- Password hashing with bcrypt
- Environment variable secrets
- Kubernetes secrets for sensitive data
- AWS IAM roles and policies
- VPC isolation
- Security group rules

## 🚀 Deployment Options

### 1. Local Development
```bash
docker-compose up
```

### 2. AWS EKS (Production)
```bash
cd infra/terraform
terraform apply

cd ../kubernetes
kubectl apply -f .
```

### 3. GitHub Actions (Automated)
```bash
# Push to main branch
git push origin main
# → Automatically deploys to EKS
```

## 🔍 Monitoring & Debugging

### Check Service Health
```bash
# Kubernetes
kubectl get pods -n ai-finance
kubectl logs -f deployment/auth-service -n ai-finance

# Infrastructure status
.\scripts\check-infrastructure.ps1

# Database inspection
.\scripts\check-database.ps1 -Table users
```

### CloudWatch Logs
```bash
# View logs
aws logs tail /aws/eks/ai-finance-eks-dev/cluster --follow
```

## 🌟 Features

- ✅ Microservices architecture
- ✅ Kubernetes deployment
- ✅ Automated CI/CD pipeline
- ✅ Database migrations with Prisma
- ✅ AWS cloud infrastructure
- ✅ Docker containerization
- ✅ JWT authentication
- ✅ File upload to S3
- ✅ AI-powered chat
- ✅ Transaction analytics
- ✅ Infrastructure as Code
- ✅ Zero-downtime deployments
- ✅ Auto-scaling ready
- ✅ Cost optimization scripts

## 🗺️ Roadmap

### Phase 1: MVP ✅
- [x] Basic microservices
- [x] Authentication
- [x] File upload
- [x] Database setup
- [x] AWS deployment
- [x] CI/CD pipeline

### Phase 2: Enhanced Features (In Progress)
- [ ] GraphQL API
- [ ] Real-time updates (WebSocket)
- [ ] Advanced analytics dashboard
- [ ] Mobile app integration
- [ ] Enhanced AI features

### Phase 3: Scale & Optimize
- [ ] Horizontal pod autoscaling
- [ ] Redis caching layer
- [ ] Message queue (SQS/Kafka)
- [ ] Prometheus + Grafana monitoring
- [ ] Multi-region deployment

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

**CI will automatically:**
- Run tests
- Build Docker images
- Validate code quality

## 📄 License

This project is proprietary and confidential.

## 👥 Team

- **DevOps**: Infrastructure & CI/CD
- **Backend**: Microservices development
- **Database**: Schema design & optimization
- **AI**: AI service integration

## 📞 Support

- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: Check `.github/README.md` for CI/CD help
- **Database Issues**: See `DATABASE_CONNECTION.md`
- **Infrastructure**: Review `infra/terraform/README.md`

## 🎯 Getting Help

| Question Type | Resource |
|---------------|----------|
| Setup CI/CD | [Setup Checklist](.github/SETUP_CHECKLIST.md) |
| Daily operations | [Quick Reference](.github/QUICK_REFERENCE.md) |
| Troubleshooting | [CI/CD README](.github/README.md) |
| Database access | [Database Guide](DATABASE_CONNECTION.md) |
| Infrastructure | [Terraform README](infra/terraform/README.md) |

---

**Built with ❤️ using NestJS, Kubernetes, and AWS**

**Last Updated**: February 17, 2026
