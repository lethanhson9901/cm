#!/bin/bash

# Create Kind cluster
echo "Creating Kind cluster..."
kind create cluster --config kind-config.yaml

# Create namespace
echo "Creating argocd namespace..."
kubectl create namespace argocd

# Install Argo CD
echo "Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Patch Argo CD server service to NodePort
echo "Patching Argo CD server service..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "http", "port": 80, "protocol": "TCP", "targetPort": 8080, "nodePort": 30080}, {"name": "https", "port": 443, "protocol": "TCP", "targetPort": 8080, "nodePort": 30443}]}}'

# Get the initial admin password
echo "Getting initial admin password..."
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo -e "\n"

echo "Argo CD is now available at: https://localhost:8443"
echo "Username: admin"
echo "Password: (shown above)"
echo "Note: You may need to accept the self-signed certificate in your browser."