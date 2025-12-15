#!/bin/bash

# ========================================
# Kubernetes Setup Script
# Creates all required secrets and configmaps
# ========================================

set -e  # Exit on error

# Configuration
NAMESPACE="chatbot-prod"
APP_NAME="sohamrepo-chatbot"

echo "=========================================="
echo "Setting up Kubernetes secrets and configs"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# Create namespace
echo ""
echo "Creating namespace..."
kubectl apply -f namespace.yaml

# ========================================
# Create Nexus Registry Secret
# ========================================
echo ""
echo "Creating Nexus registry secret..."
read -p "Enter Nexus username: " NEXUS_USER
read -sp "Enter Nexus password: " NEXUS_PASS
echo ""

kubectl create secret docker-registry nexus-secret \
  --docker-server=127.0.0.1:30085 \
  --docker-username=$NEXUS_USER \
  --docker-password=$NEXUS_PASS \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Nexus secret created"

# ========================================
# Create Database Secrets (Optional)
# Skip if using deployment-simple.yaml
# ========================================
echo ""
read -p "Does your app need database connectivity? (y/n): " NEED_DB

if [[ $NEED_DB == "y" || $NEED_DB == "Y" ]]; then
    echo ""
    echo "Creating database credentials..."
    read -p "Enter DB username: " DB_USER
    read -sp "Enter DB password: " DB_PASS
    echo ""
    read -p "Enter DB name: " DB_NAME
    
    kubectl create secret generic db-secret \
      --from-literal=DB_USER=$DB_USER \
      --from-literal=DB_PASSWORD=$DB_PASS \
      --from-literal=DB_NAME=$DB_NAME \
      --namespace=$NAMESPACE \
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✓ Database secret created"
    
    # Create database config
    echo ""
    echo "Creating database config..."
    read -p "Enter DB host: " DB_HOST
    read -p "Enter DB port (default: 5432): " DB_PORT
    DB_PORT=${DB_PORT:-5432}
    
    kubectl create configmap db-config \
      --from-literal=DB_HOST=$DB_HOST \
      --from-literal=DB_PORT=$DB_PORT \
      --namespace=$NAMESPACE \
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✓ Database config created"
else
    echo "Skipping database setup. Use deployment-simple.yaml for deployment."
fi

# ========================================
# Verify Secrets
# ========================================
echo ""
echo "=========================================="
echo "Setup Complete! Verifying..."
echo "=========================================="
echo ""
echo "Secrets in namespace '$NAMESPACE':"
kubectl get secrets -n $NAMESPACE

echo ""
echo "ConfigMaps in namespace '$NAMESPACE':"
kubectl get configmaps -n $NAMESPACE

echo ""
echo "=========================================="
echo "✓ Setup completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run: ./deploy.sh to deploy the application"
echo "  2. Or manually: kubectl apply -f deployment.yaml"
echo ""
