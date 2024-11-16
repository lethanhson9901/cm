# docs/gke-deployment.md
# Google Kubernetes Engine Deployment Guide

## Overview
This guide describes the process of deploying the application to Google Kubernetes Engine (GKE).

## Prerequisites
- Google Cloud SDK installed and configured
- Kubernetes CLI (kubectl)
- Access to GitHub Container Registry

## Architecture
```
                                ┌───────────────┐
                                │ Cloud DNS    │
                                └──────┬───────┘
                                       │
                                ┌──────┴───────┐
                                │ Ingress      │
                                └──────┬───────┘
                                       │
                    ┌────────────┬─────┴─────┬────────────┐
                    │            │           │            │
              ┌─────┴─────┐┌────┴─────┐┌────┴─────┐┌────┴─────┐
              │   Pod     ││   Pod    ││   Pod    ││   Pod    │
              │          ││          ││          ││          │
              └─────┬────┘└────┬─────┘└────┬─────┘└────┬─────┘
                    │          │           │           │
              ┌─────┴──────────┴───────────┴───────────┴─────┐
              │              Cloud SQL                        │
              └───────────────────────────────────────────────┘
```

## Deployment Steps
1. Cluster Setup
```bash
cd platforms/gke/terraform
terraform init
terraform apply
```

2. Application Deployment
```bash
cd platforms/gke
./scripts/deploy.sh prod
```

## Monitoring
- Cloud Monitoring
- Prometheus Operator
- Loki for logging

## Scaling
- Horizontal Pod Autoscaling
- Vertical Pod Autoscaling
- Cluster Autoscaling
