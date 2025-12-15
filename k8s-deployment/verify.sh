#!/bin/bash

# ========================================
# Kubernetes Verification Script
# Verifies the deployment status
# ========================================

# Configuration
NAMESPACE="chatbot-prod"
APP_NAME="sohamrepo-chatbot"

echo "=========================================="
echo "Verifying $APP_NAME deployment"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# ========================================
# Check Namespace
# ========================================
echo ""
echo "1. Checking namespace..."
if kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "   ✓ Namespace '$NAMESPACE' exists"
else
    echo "   ✗ Namespace '$NAMESPACE' NOT FOUND!"
    exit 1
fi

# ========================================
# Check Secrets
# ========================================
echo ""
echo "2. Checking secrets..."
if kubectl get secret nexus-secret -n $NAMESPACE &> /dev/null; then
    echo "   ✓ nexus-secret exists"
else
    echo "   ✗ nexus-secret NOT FOUND!"
fi

if kubectl get secret db-secret -n $NAMESPACE &> /dev/null; then
    echo "   ✓ db-secret exists"
else
    echo "   ⚠ db-secret not found (OK if using simple deployment)"
fi

# ========================================
# Check ConfigMaps
# ========================================
echo ""
echo "3. Checking configmaps..."
if kubectl get configmap db-config -n $NAMESPACE &> /dev/null; then
    echo "   ✓ db-config exists"
else
    echo "   ⚠ db-config not found (OK if using simple deployment)"
fi

# ========================================
# Check Deployment
# ========================================
echo ""
echo "4. Checking deployment..."
if kubectl get deployment ${APP_NAME}-deployment -n $NAMESPACE &> /dev/null; then
    echo "   ✓ Deployment exists"
    
    # Check replicas
    DESIRED=$(kubectl get deployment ${APP_NAME}-deployment -n $NAMESPACE -o jsonpath='{.spec.replicas}')
    READY=$(kubectl get deployment ${APP_NAME}-deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    
    echo "   Replicas: $READY/$DESIRED ready"
    
    if [ "$READY" == "$DESIRED" ]; then
        echo "   ✓ All replicas are ready"
    else
        echo "   ✗ Not all replicas are ready!"
    fi
else
    echo "   ✗ Deployment NOT FOUND!"
fi

# ========================================
# Check Pods
# ========================================
echo ""
echo "5. Checking pods..."
kubectl get pods -n $NAMESPACE -l app=$APP_NAME

POD_STATUS=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{.items[0].status.phase}')
if [ "$POD_STATUS" == "Running" ]; then
    echo "   ✓ Pod is running"
else
    echo "   ⚠ Pod status: $POD_STATUS"
fi

# ========================================
# Check Service
# ========================================
echo ""
echo "6. Checking service..."
if kubectl get svc ${APP_NAME}-service -n $NAMESPACE &> /dev/null; then
    echo "   ✓ Service exists"
    kubectl get svc ${APP_NAME}-service -n $NAMESPACE
else
    echo "   ✗ Service NOT FOUND!"
fi

# ========================================
# Check Ingress
# ========================================
echo ""
echo "7. Checking ingress..."
if kubectl get ingress ${APP_NAME}-ingress -n $NAMESPACE &> /dev/null; then
    echo "   ✓ Ingress exists"
    kubectl get ingress ${APP_NAME}-ingress -n $NAMESPACE
else
    echo "   ✗ Ingress NOT FOUND!"
fi

# ========================================
# Check PVC
# ========================================
echo ""
echo "8. Checking persistent volume claim..."
if kubectl get pvc app-pvc -n $NAMESPACE &> /dev/null; then
    echo "   ✓ PVC exists"
    kubectl get pvc app-pvc -n $NAMESPACE
else
    echo "   ⚠ PVC not found (OK if not using storage)"
fi

# ========================================
# Test Health Endpoint
# ========================================
echo ""
echo "9. Testing health endpoint..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{.items[0].metadata.name}')

if [ -n "$POD_NAME" ]; then
    echo "   Testing /health on pod: $POD_NAME"
    if kubectl exec -n $NAMESPACE $POD_NAME -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8501/health | grep -q "200"; then
        echo "   ✓ Health check passed (HTTP 200)"
    else
        echo "   ✗ Health check failed!"
    fi
else
    echo "   ⚠ No pod found to test"
fi

# ========================================
# Recent Events
# ========================================
echo ""
echo "10. Recent events in namespace:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

# ========================================
# Summary
# ========================================
echo ""
echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
echo ""
echo "Quick Commands:"
echo "  View logs:    kubectl logs -f deployment/${APP_NAME}-deployment -n $NAMESPACE"
echo "  Describe pod: kubectl describe pod -l app=$APP_NAME -n $NAMESPACE"
echo "  Shell access: kubectl exec -it deployment/${APP_NAME}-deployment -n $NAMESPACE -- /bin/sh"
echo "  Port forward: kubectl port-forward svc/${APP_NAME}-service 8501:8501 -n $NAMESPACE"
echo ""
echo "Access application:"
echo "  Internal: http://${APP_NAME}-service.${NAMESPACE}.svc.cluster.local:8501"
echo "  External: http://chatbot.imcc.com"
echo ""
