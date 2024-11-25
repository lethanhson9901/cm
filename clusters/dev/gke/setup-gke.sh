#!/bin/bash

#############################################
# GKE Cluster Configuration Script
# Best Practices & Cost Optimized
#############################################

# Error handling
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%dT%H:%M:%S%z')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $1${NC}"
    exit 1
}


#############################################
# Create VPC and Subnet
#############################################
create_network() {
    log "Creating VPC network and subnet..."
    
    # Create VPC
    gcloud compute networks create ${VPC_NAME} \
        --project=${PROJECT_ID} \
        --subnet-mode=custom

    # Create subnet
    gcloud compute networks subnets create ${SUBNET_NAME} \
        --project=${PROJECT_ID} \
        --network=${VPC_NAME} \
        --region=${ZONE%-*} \
        --range=${SUBNET_RANGE} \
        --secondary-range=${PODS_RANGE_NAME}=${PODS_RANGE},${SERVICES_RANGE_NAME}=${SERVICES_RANGE}

    log "VPC and subnet created successfully"
}

#############################################
# Create GKE Cluster
#############################################
create_cluster() {
    log "Creating GKE cluster..."

    gcloud container clusters create ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --network=${VPC_NAME} \
        --subnetwork=${SUBNET_NAME} \
        --cluster-secondary-range-name=${PODS_RANGE_NAME} \
        --services-secondary-range-name=${SERVICES_RANGE_NAME} \
        --enable-private-nodes \
        --enable-private-endpoint \
        --master-ipv4-cidr=${MASTER_IPV4_CIDR} \
        --no-enable-master-authorized-networks \
        --machine-type=${MACHINE_TYPE} \
        --spot \
        --num-nodes=${INITIAL_NODES} \
        --min-nodes=${MIN_NODES} \
        --max-nodes=${MAX_NODES} \
        --disk-type=${DISK_TYPE} \
        --disk-size=${DISK_SIZE} \
        --enable-network-policy \
        --workload-pool=${PROJECT_ID}.svc.id.goog \
        --enable-binauthz \
        --enable-autorepair \
        --enable-autoupgrade \
        --maintenance-window-start=${MAINTENANCE_WINDOW} \
        --enable-ip-alias \
        --logging=SYSTEM,WORKLOAD \
        --monitoring=SYSTEM \
        --node-labels=${NODE_LABELS} \
        --node-taints=${NODE_TAINTS} \
        --enable-vertical-pod-autoscaling \
        --enable-master-authorized-networks \
        --master-authorized-networks=${AUTHORIZED_IP} \
        --release-channel=regular

    log "Cluster created successfully"
}

#############################################
# Configure Cluster Policies
#############################################
configure_policies() {
    log "Configuring cluster policies..."

    # Enable network policy
    gcloud container clusters update ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --enable-network-policy

    # Configure pod security policy
    kubectl apply -f - <<EOF
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  readOnlyRootFilesystem: true
EOF

    log "Cluster policies configured successfully"
}

#############################################
# Main Execution
#############################################
main() {
    # Check if required commands exist
    command -v gcloud >/dev/null 2>&1 || error "gcloud is required but not installed"
    command -v kubectl >/dev/null 2>&1 || error "kubectl is required but not installed"

    # Check if project ID is set
    [[ "${PROJECT_ID}" == "your-project-id" ]] && error "Please set PROJECT_ID variable"

    # Create network
    create_network

    # Create cluster
    create_cluster

    # Configure policies
    configure_policies

    log "GKE cluster setup completed successfully!"
    log "Cluster name: ${CLUSTER_NAME}"
    log "Zone: ${ZONE}"
    log "Get credentials with: gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE} --project=${PROJECT_ID}"
}

# Run main function
main