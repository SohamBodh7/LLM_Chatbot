# CI/CD Pipeline - Quick Configuration Guide

## 🎯 Overview

This guide helps you quickly configure the CI/CD pipeline and Kubernetes deployment files for the chatbot project.

## 📋 Files Created

### Kubernetes Deployment Files (k8s-deployment/)
- ✅ `namespace.yaml` - Namespace configuration
- ✅ `deployment.yaml` - Application deployment with health probes
- ✅ `service.yaml` - ClusterIP service
- ✅ `pvc.yaml` - PersistentVolumeClaim (optional, for storage)
- ✅ `ingress.yaml` - Nginx ingress for external access
- ✅ `README.md` - Detailed deployment documentation

### Existing Pipeline Files
- ✅ `Jenkinsfile` - Jenkins CI/CD pipeline (already exists)
- ✅ `Dockerfile` - Container image definition (already exists)
- ✅ `sonar-project.properties` - SonarQube configuration (already exists)

## ⚙️ Configuration Checklist

### Step 1: Update Kubernetes Files

Replace these placeholders in all `k8s-deployment/*.yaml` files:

```bash
# Recommended values for your chatbot:
<NAMESPACE>           → chatbot-prod
<APP_NAME>            → sohamrepo-chatbot
<APP_PORT>            → 8501
<PROJECT_NAMESPACE>   → sohamrepo
<TAG>                 → latest (or use ${BUILD_NUMBER} from Jenkins)
<APP_DOMAIN>          → chatbot
```

### Step 2: Update Jenkinsfile (if needed)

Your current `Jenkinsfile` already has most configurations. Verify these:

```groovy
APP_NAME    = "sohamrepo-chatbot"  ✅ Already configured
NEXUS_URL   = "nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"  ✅ Already configured
SONAR_HOST_URL = "http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000"  ✅ Already configured
```

### Step 3: Create Kubernetes Secrets/ConfigMaps

Run these commands to create required secrets (update values):

```bash
# Set your namespace
export NAMESPACE="chatbot-prod"

# 1. Create namespace first
kubectl apply -f k8s-deployment/namespace.yaml

# 2. Database credentials (if you use a database)
kubectl create secret generic db-secret \
  --from-literal=DB_USER=your_username \
  --from-literal=DB_PASSWORD=your_password \
  --from-literal=DB_NAME=your_database \
  -n $NAMESPACE

# 3. Database connection info
kubectl create configmap db-config \
  --from-literal=DB_HOST=your_host \
  --from-literal=DB_PORT=5432 \
  -n $NAMESPACE

# 4. Nexus registry credentials (for pulling images)
kubectl create secret docker-registry nexus-secret \
  --docker-server=127.0.0.1:30085 \
  --docker-username=your_nexus_user \
  --docker-password=your_nexus_password \
  -n $NAMESPACE
```

### Step 4: Configure Jenkins Credentials

Ensure these credentials exist in Jenkins:

1. **nexus-docker-login** (Username/Password)
   - ID: `nexus-docker-login`
   - Type: Username with password
   - For: Docker registry authentication

2. **2401023-chatbot** (Secret Text)
   - ID: `2401023-chatbot`
   - Type: Secret text
   - For: SonarQube authentication token

3. **kubeconfig-secret** (Secret File) - if deploying from Jenkins
   - ID: `kubeconfig-secret`
   - Type: Secret file
   - For: Kubernetes deployment authentication

## 🚀 Deployment Workflow

### Option A: Jenkins Pipeline (Automated)

1. Push code to your Git repository
2. Jenkins will automatically:
   - Run SonarQube analysis
   - Build Docker image
   - Push to Nexus registry
   - (Optional) Deploy to Kubernetes

### Option B: Manual Kubernetes Deployment

```bash
# After Docker image is in Nexus, deploy manually:

# 1. Apply all configs
kubectl apply -f k8s-deployment/pvc.yaml        # Optional
kubectl apply -f k8s-deployment/deployment.yaml
kubectl apply -f k8s-deployment/service.yaml
kubectl apply -f k8s-deployment/ingress.yaml

# 2. Check status
kubectl get all -n chatbot-prod

# 3. View logs
kubectl logs -f deployment/sohamrepo-chatbot-deployment -n chatbot-prod
```

## 🏗️ Current Jenkins Pipeline Stages

Your existing Jenkinsfile includes:

1. ✅ **Checkout Code** - Get code from Git
2. ✅ **Prepare Configs** - Setup Streamlit secrets
3. ✅ **SonarQube Analysis** - Code quality checks
4. ✅ **Build Docker Image** - Create container image
5. ✅ **Push to Nexus** - Store image in registry

### To Add: Kubernetes Deployment Stage

If you want Jenkins to also deploy to Kubernetes, add this stage to your Jenkinsfile:

```groovy
stage('6. Deploy to Kubernetes') {
    steps {
        container('kubectl') {
            withCredentials([file(credentialsId: 'kubeconfig-secret', variable: 'KUBECONFIG')]) {
                sh '''
                    # Update image tag in deployment
                    sed -i "s|<TAG>|${IMAGE_TAG}|g" k8s-deployment/deployment.yaml
                    sed -i "s|<NAMESPACE>|chatbot-prod|g" k8s-deployment/*.yaml
                    sed -i "s|<APP_NAME>|${APP_NAME}|g" k8s-deployment/*.yaml
                    sed -i "s|<APP_PORT>|8501|g" k8s-deployment/*.yaml
                    sed -i "s|<PROJECT_NAMESPACE>|sohamrepo|g" k8s-deployment/*.yaml
                    sed -i "s|<APP_DOMAIN>|chatbot|g" k8s-deployment/*.yaml
                    
                    # Apply configurations
                    kubectl apply -f k8s-deployment/deployment.yaml
                    kubectl apply -f k8s-deployment/service.yaml
                    kubectl apply -f k8s-deployment/ingress.yaml
                    
                    # Wait for rollout
                    kubectl rollout status deployment/${APP_NAME}-deployment -n chatbot-prod
                '''
            }
        }
    }
}
```

## 📊 Quick Reference: Placeholder Values

| File | Placeholders to Replace |
|------|------------------------|
| `namespace.yaml` | `<NAMESPACE>` |
| `deployment.yaml` | All 6 placeholders |
| `service.yaml` | `<NAMESPACE>`, `<APP_NAME>`, `<APP_PORT>` |
| `pvc.yaml` | `<NAMESPACE>` |
| `ingress.yaml` | `<NAMESPACE>`, `<APP_NAME>`, `<APP_PORT>`, `<APP_DOMAIN>` |

## ✅ Verification Steps

After deployment:

```bash
# 1. Check if pods are running
kubectl get pods -n chatbot-prod

# 2. Check service
kubectl get svc -n chatbot-prod

# 3. Check ingress
kubectl get ingress -n chatbot-prod

# 4. Test health endpoint
kubectl exec -it deployment/sohamrepo-chatbot-deployment -n chatbot-prod -- curl localhost:8501/health

# 5. Access application
# Internal: http://sohamrepo-chatbot-service.chatbot-prod.svc.cluster.local:8501
# External: http://chatbot.imcc.com
```

## 🔍 Troubleshooting

### Common Issues:

**Pod won't start?**
```bash
kubectl describe pod <pod-name> -n chatbot-prod
kubectl logs <pod-name> -n chatbot-prod
```

**Image pull error?**
- Check if `nexus-secret` exists and has correct credentials
- Verify image exists: `127.0.0.1:30085/sohamrepo/sohamrepo-chatbot:latest`

**Health check failing?**
- Ensure your app has `/health` endpoint
- Check if app is listening on port 8501

## 📚 Next Steps

1. ✅ Update placeholders in k8s-deployment files
2. ✅ Create secrets and configmaps in Kubernetes
3. ✅ Verify Jenkins credentials
4. ✅ Test the pipeline
5. ✅ Deploy to Kubernetes
6. ✅ Verify application is running

For detailed information, see:
- `k8s-deployment/README.md` - Comprehensive deployment guide
- `Jenkinsfile` - Pipeline configuration
- `CI_CD Pipeline Reference Guide.pdf` - Full reference documentation

---
**Note**: If your chatbot doesn't use a database, you can remove the database-related environment variables from `deployment.yaml`.
