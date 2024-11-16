# docs/monitoring-setup.md
# Monitoring Setup Guide

## Components
1. Metrics
   - Prometheus
   - Grafana
   - Platform-specific metrics (CloudWatch/Cloud Monitoring)

2. Logging
   - Fluentd
   - Elasticsearch
   - Kibana

3. Tracing
   - Jaeger/OpenTelemetry

## Setup Instructions

### Prometheus
1. Installation
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

2. Configuration
- Metrics retention
- Alerting rules
- Service discovery

### Grafana
1. Dashboards
- Application metrics
- Platform metrics
- Resource utilization

2. Alerting
- Alert channels
- Alert rules
- On-call rotations

### Logging
1. Fluentd Setup
```bash
kubectl create namespace logging
kubectl apply -f shared/logging/fluentd/
```

2. Log Analysis
- Log parsing rules
- Index management
- Retention policies