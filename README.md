# README.md
# Multi-Platform Infrastructure

This repository contains the infrastructure as code (IaC) and deployment configurations for our application across multiple platforms:
- AWS EC2 with Docker Compose
- Google Kubernetes Engine (GKE)
- On-premise (planned)

## Structure
```
cm/
├── apps/          # Application-specific configurations
├── shared/        # Shared resources (monitoring, logging, security)
├── platforms/     # Platform-specific configurations
└── environments/  # Environment-specific variables and secrets
```

## Prerequisites
- Terraform >= 1.0.0
- AWS CLI >= 2.0.0
- Google Cloud SDK >= 400.0.0
- Docker >= 20.10.0
- Docker Compose >= 2.0.0
- kubectl >= 1.24.0

## Quick Start
1. Clone the repository
```bash
git clone https://github.com/lethanhson9901/cm.git
cd cm
```

2. Set up platform credentials
```bash
# For AWS
aws configure

# For GKE
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

3. Deploy to platform
```bash
# For AWS
./platforms/aws/scripts/deploy.sh prod

# For GKE
./platforms/gke/scripts/deploy.sh prod
```

## Documentation
- [AWS Deployment Guide](docs/aws-deployment.md)
- [GKE Deployment Guide](docs/gke-deployment.md)
- [Monitoring Setup](docs/monitoring-setup.md)

## Security
For security concerns, please contact security@your-org.com