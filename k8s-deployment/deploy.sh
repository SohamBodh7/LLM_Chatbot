#!/bin/bash

# ========================================
# Kubernetes Deployment Script
# Deploys the chatbot application
# ========================================

set -e  # Exit on error

# Configuration
NAMESPACE="chatbot-prod"
APP_NAME="sohamrepo-chatbot"

echo "=========================================="
echo "Deploying $APP_NAME to Kubernetes"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "Error: Namespace '$NAMESPACE' does not exist!"
    echo "Please run ./setup.sh first"
    exit 1
fi

# Check if nexus-secret exists
if ! kubectl get secret nexus-secret -n $NAMESPACE &> /dev/null; then
    echo "Error: nexus-secret not found in namespace '$NAMESPACE'!"
    echo "Please run ./setup.sh first"
    exit 1
fi

# ========================================
# Choose Deployment Type
# ========================================
echo ""
echo "Choose deployment type:"
echo "  1) Full deployment (with database + storage)"
echo "  2) No storage (database only)"
echo "  3) Simple (no database, no storage)"
echo ""
read -p "Enter choice [1-3]: " DEPLOY_TYPE

case $DEPLOY_TYPE in
    1)
        DEPLOYMENT_FILE="deployment.yaml"
        NEEDS_PVC=true
        echo "Using: Full deployment with database and storage"
        ;;
    2)
        DEPLOYMENT_FILE="deployment-no-storage.yaml"
        NEEDS_PVC=false
        echo "Using: Deployment with database, no storage"
        ;;
    3)
        DEPLOYMENT_FILE="deployment-simple.yaml"
        NEEDS_PVC=false
        echo "Using: Simple deployment (no database, no storage)"
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

# ========================================
# Deploy Resources
# ========================================
echo ""
echo "Deploying resources..."

# Apply PVC if needed
if [ "$NEEDS_PVC" = true ]; then
    echo "  → Creating PersistentVolumeClaim..."
    kubectl apply -f pvc.yaml
fi

# Apply deployment
echo "  → Creating deployment..."
kubectl apply -f $DEPLOYMENT_FILE

# Apply service
echo "  → Creating service..."
kubectl apply -f service.yaml

# Apply ingress
echo "  → Creating ingress..."
kubectl apply -f ingress.yaml

echo ""
echo "Resources applied successfully!"

# ========================================
# Wait for Deployment
# ========================================
echo ""
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/${APP_NAME}-deployment -n $NAMESPACE --timeout=5m

# ========================================
# Show Status
# ========================================
echo ""
echo "=========================================="
echo "✓ Deployment completed successfully!"
echo "=========================================="
echo ""
echo "Pod status:"
kubectl get pods -n $NAMESPACE -l app=$APP_NAME

echo ""
echo "Service details:"
kubectl get svc -n $NAMESPACE -l app=$APP_NAME

echo ""
echo "Ingress details:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "=========================================="
echo "Application Access:"
echo "=========================================="
echo "  Internal: http://${APP_NAME}-service.${NAMESPACE}.svc.cluster.local:8501"
echo "  External: http://chatbot.imcc.com"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/${APP_NAME}-deployment -n $NAMESPACE"
echo ""
echo "To check pod details:"
echo "  kubectl describe pod -l app=$APP_NAME -n $NAMESPACE"
echo ""
