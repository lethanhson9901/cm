# docs/aws-deployment.md
# AWS Deployment Guide

## Overview
This guide describes the process of deploying the application to AWS using Docker Compose on EC2 instances.

## Prerequisites
- AWS CLI configured with appropriate permissions
- Access to GitHub Container Registry
- SSH key pair for EC2 access

## Architecture
```
                                   ┌─────────────┐
                                   │   Route53   │
                                   └─────┬───────┘
                                         │
                                   ┌─────┴───────┐
                                   │     ALB     │
                                   └─────┬───────┘
                                         │
                    ┌──────────────┬─────┴─────┬──────────────┐
                    │              │           │              │
              ┌─────┴─────┐ ┌─────┴─────┐┌────┴──────┐┌─────┴─────┐
              │   EC2     │ │    EC2    ││    EC2    ││    EC2    │
              │  Docker   │ │   Docker  ││   Docker  ││   Docker  │
              └─────┬─────┘ └─────┬─────┘└─────┬─────┘└─────┬─────┘
                    │             │            │            │
              ┌─────┴─────────────┴────────────┴────────────┴─────┐
              │                    RDS Aurora                      │
              └───────────────────────────────────────────────────┘
```

## Deployment Steps
1. Infrastructure Setup
```bash
cd platforms/aws/terraform
terraform init
terraform apply
```

2. Application Deployment
```bash
cd platforms/aws
./scripts/deploy.sh prod
```

## Monitoring
- CloudWatch Metrics
- Prometheus + Grafana
- ELK Stack for logging

## Backup and Recovery
Automated backups are configured for:
- RDS databases
- EC2 instance states
- Application data volumes