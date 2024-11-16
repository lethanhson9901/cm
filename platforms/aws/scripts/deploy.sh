#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Load helper functions
source "$(dirname "$0")/utils.sh"

# Script variables
ENVIRONMENT=${1:-}
VERSION=${2:-latest}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Validate input
if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 <environment> [version]"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Environment must be dev, staging, or prod"
    exit 1
fi

# Load environment variables
set -a
source "${PROJECT_ROOT}/environments/aws/${ENVIRONMENT}/env.conf"
set +a

log_info "Starting deployment to AWS ${ENVIRONMENT} environment"

# Ensure AWS CLI is configured
check_aws_credentials

# Apply infrastructure changes
log_info "Applying infrastructure changes"
(
    cd "${PROJECT_ROOT}/platforms/aws/terraform"
    terraform init
    terraform workspace select "${ENVIRONMENT}" || terraform workspace new "${ENVIRONMENT}"
    terraform apply -auto-approve \
        -var="environment=${ENVIRONMENT}" \
        -var="aws_region=${AWS_REGION}"
)

# Get EC2 instances
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=${ENVIRONMENT}" \
              "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

# Deploy to each instance
for INSTANCE_ID in $INSTANCE_IDS; do
    log_info "Deploying to instance ${INSTANCE_ID}"
    
    # Copy deployment files
    aws ssm send-command \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters commands=["
            cd /opt/app && \
            aws s3 cp s3://${ARTIFACT_BUCKET}/docker-compose.${ENVIRONMENT}.yml docker-compose.yml && \
            docker-compose pull && \
            docker-compose up -d --remove-orphans
        "] \
        --comment "Deployment ${VERSION} to ${ENVIRONMENT}"
        
    # Verify deployment
    wait_for_healthy_status "${INSTANCE_ID}"
done

log_info "Deployment completed successfully"
