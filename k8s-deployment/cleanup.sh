#!/bin/bash

# ========================================
# Kubernetes Cleanup Script
# Removes all resources for the chatbot
# ========================================

set -e  # Exit on error

# Configuration
NAMESPACE="chatbot-prod"
APP_NAME="sohamrepo-chatbot"

echo "=========================================="
echo "⚠️  CLEANUP SCRIPT"
echo "This will DELETE all resources for $APP_NAME"
echo "Namespace: $NAMESPACE"
echo "=========================================="
echo ""
echo "This will delete:"
echo "  - Deployment"
echo "  - Service"
echo "  - Ingress"
echo "  - PersistentVolumeClaim"
echo "  - Secrets (optional)"
echo "  - ConfigMaps (optional)"
echo "  - Namespace (optional)"
echo ""

read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [[ $CONFIRM != "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# ========================================
# Delete Resources
# ========================================
echo ""
echo "Deleting deployment resources..."

# Delete ingress
if kubectl get ingress ${APP_NAME}-ingress -n $NAMESPACE &> /dev/null; then
    echo "  → Deleting ingress..."
    kubectl delete ingress ${APP_NAME}-ingress -n $NAMESPACE
    echo "  ✓ Ingress deleted"
fi

# Delete service
if kubectl get svc ${APP_NAME}-service -n $NAMESPACE &> /dev/null; then
    echo "  → Deleting service..."
    kubectl delete svc ${APP_NAME}-service -n $NAMESPACE
    echo "  ✓ Service deleted"
fi

# Delete deployment
if kubectl get deployment ${APP_NAME}-deployment -n $NAMESPACE &> /dev/null; then
    echo "  → Deleting deployment..."
    kubectl delete deployment ${APP_NAME}-deployment -n $NAMESPACE
    echo "  ✓ Deployment deleted"
fi

# Delete PVC
if kubectl get pvc app-pvc -n $NAMESPACE &> /dev/null; then
    echo "  → Deleting PVC..."
    kubectl delete pvc app-pvc -n $NAMESPACE
    echo "  ✓ PVC deleted"
fi

# ========================================
# Optional: Delete Secrets and ConfigMaps
# ========================================
echo ""
read -p "Delete secrets and configmaps? (y/n): " DELETE_SECRETS

if [[ $DELETE_SECRETS == "y" || $DELETE_SECRETS == "Y" ]]; then
    # Delete db-secret
    if kubectl get secret db-secret -n $NAMESPACE &> /dev/null; then
        echo "  → Deleting db-secret..."
        kubectl delete secret db-secret -n $NAMESPACE
    fi
    
    # Delete db-config
    if kubectl get configmap db-config -n $NAMESPACE &> /dev/null; then
        echo "  → Deleting db-config..."
        kubectl delete configmap db-config -n $NAMESPACE
    fi
    
    # Delete nexus-secret
    if kubectl get secret nexus-secret -n $NAMESPACE &> /dev/null; then
        echo "  → Deleting nexus-secret..."
        kubectl delete secret nexus-secret -n $NAMESPACE
    fi
    
    echo "  ✓ Secrets and configmaps deleted"
fi

# ========================================
# Optional: Delete Namespace
# ========================================
echo ""
read -p "Delete entire namespace '$NAMESPACE'? (y/n): " DELETE_NAMESPACE

if [[ $DELETE_NAMESPACE == "y" || $DELETE_NAMESPACE == "Y" ]]; then
    echo "  → Deleting namespace..."
    kubectl delete namespace $NAMESPACE
    echo "  ✓ Namespace deleted"
fi

# ========================================
# Verify Cleanup
# ========================================
echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""

if kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "Remaining resources in namespace '$NAMESPACE':"
    kubectl get all -n $NAMESPACE
else
    echo "Namespace '$NAMESPACE' has been deleted."
fi

echo ""
echo "To redeploy:"
echo "  1. Run: ./setup.sh"
echo "  2. Run: ./deploy.sh"
echo ""
