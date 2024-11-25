#!/bin/bash

# Error handling
set -euo pipefail

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $1${NC}"
    exit 1
}

#############################################
# Configuration
#############################################
# You can either set these as environment variables or modify them here
PROJECT_ID=${PROJECT_ID:-"your-project-id"}
CLUSTER_NAME=${CLUSTER_NAME:-"optimized-cluster"}
ZONE=${ZONE:-"asia-southeast1-a"}

#############################################
# Get current IP and format for GKE
#############################################
get_current_ip() {
    # Get current public IP
    CURRENT_IP=$(curl -s ifconfig.me)
    if [ -z "$CURRENT_IP" ]; then
        error "Failed to get current IP address"
    }
    echo "${CURRENT_IP}/32"
}

#############################################
# Get existing authorized networks
#############################################
get_existing_networks() {
    log "Getting existing authorized networks..."
    EXISTING_NETWORKS=$(gcloud container clusters describe ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --format='get(masterAuthorizedNetworksConfig.cidrBlocks[].cidrBlock)' \
        2>/dev/null || echo "")
    echo "$EXISTING_NETWORKS"
}

#############################################
# Update authorized networks
#############################################
update_authorized_networks() {
    local NEW_IP=$1
    local EXISTING_NETWORKS=$2
    
    log "Updating master authorized networks..."
    
    # Start building the command
    CMD="gcloud container clusters update ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --enable-master-authorized-networks \
        --master-authorized-networks"

    # If there are existing networks, include them
    if [ ! -z "$EXISTING_NETWORKS" ]; then
        # Convert newlines to commas and append new IP
        NETWORKS=$(echo "$EXISTING_NETWORKS" | tr '\n' ',' | sed 's/,$//')
        CMD+="$NETWORKS,$NEW_IP"
    else
        # Just use the new IP
        CMD+="$NEW_IP"
    fi

    # Execute the command
    eval $CMD

    log "Master authorized networks updated successfully"
}

#############################################
# Remove an IP from authorized networks
#############################################
remove_ip() {
    local IP_TO_REMOVE=$1
    local EXISTING_NETWORKS=$(get_existing_networks)

    # Remove the specified IP from the list
    NEW_NETWORKS=$(echo "$EXISTING_NETWORKS" | grep -v "^$IP_TO_REMOVE$" || true)

    if [ -z "$NEW_NETWORKS" ]; then
        error "Cannot remove all authorized networks. At least one IP must remain authorized."
    fi

    # Convert newlines to commas
    NETWORKS_STRING=$(echo "$NEW_NETWORKS" | tr '\n' ',' | sed 's/,$//')

    log "Removing IP $IP_TO_REMOVE from authorized networks..."
    
    gcloud container clusters update ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --enable-master-authorized-networks \
        --master-authorized-networks="$NETWORKS_STRING"

    log "IP removed successfully"
}

#############################################
# List all authorized IPs
#############################################
list_authorized_ips() {
    log "Currently authorized IPs:"
    gcloud container clusters describe ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --format='table(masterAuthorizedNetworksConfig.cidrBlocks[].cidrBlock,masterAuthorizedNetworksConfig.cidrBlocks[].displayName)' \
        2>/dev/null || echo "No authorized networks found"
}

#############################################
# Print usage
#############################################
usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  add        Add current IP to authorized networks"
    echo "  remove IP  Remove specified IP from authorized networks"
    echo "  list       List all currently authorized IPs"
    echo "  help       Display this help message"
    exit 1
}

#############################################
# Main
#############################################
main() {
    # Check if required commands exist
    command -v gcloud >/dev/null 2>&1 || error "gcloud is required but not installed"
    
    # Check if project ID is set
    [[ "${PROJECT_ID}" == "your-project-id" ]] && error "Please set PROJECT_ID variable"

    case "${1:-help}" in
        "add")
            NEW_IP=$(get_current_ip)
            EXISTING_NETWORKS=$(get_existing_networks)
            update_authorized_networks "$NEW_IP" "$EXISTING_NETWORKS"
            ;;
        "remove")
            if [ -z "${2:-}" ]; then
                error "Please specify IP to remove"
            fi
            remove_ip "$2"
            ;;
        "list")
            list_authorized_ips
            ;;
        *)
            usage
            ;;
    esac
}

# Run main function with all arguments
main "$@"