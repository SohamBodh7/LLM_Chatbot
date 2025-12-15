# Kubernetes Deployment Configuration

This directory contains all the Kubernetes configuration files needed for deploying the chatbot application.

## 📁 Files Overview

- **`namespace.yaml`**: Creates a dedicated namespace for the application
- **`deployment.yaml`**: Main application deployment configuration with health probes and resource limits
- **`service.yaml`**: ClusterIP service for internal cluster communication
- **`pvc.yaml`**: PersistentVolumeClaim for optional persistent storage (1Gi)
- **`ingress.yaml`**: Nginx ingress configuration for external HTTP access

## 🔧 Configuration Placeholders

Before deploying, replace the following placeholders in the YAML files:

### Required Placeholders

| Placeholder | Description | Example |
|------------|-------------|---------|
| `<NAMESPACE>` | Kubernetes namespace name | `chatbot-prod` |
| `<APP_NAME>` | Application name | `sohamrepo-chatbot` |
| `<APP_PORT>` | Application port number | `8501` (for Streamlit) |
| `<PROJECT_NAMESPACE>` | Nexus/Registry project namespace | `your-project` |
| `<TAG>` | Docker image tag | `latest` or `${BUILD_NUMBER}` |
| `<APP_DOMAIN>` | Domain for ingress | `chatbot` (results in chatbot.imcc.com) |

### Example Configuration

For a chatbot application:
```yaml
namespace: "chatbot-prod"
app_name: sohamrepo-chatbot
app_port: 8501
project_namespace: sohamrepo
tag: latest
app_domain: chatbot
```

## 🚀 Deployment Steps

### 1. Configure Secrets and ConfigMaps

Before deploying, ensure the following secrets and configmaps exist:

```bash
# Database Secret (required)
kubectl create secret generic db-secret \
  --from-literal=DB_USER=your_db_user \
  --from-literal=DB_PASSWORD=your_db_password \
  --from-literal=DB_NAME=your_db_name \
  -n <NAMESPACE>

# Database ConfigMap (required)
kubectl create configmap db-config \
  --from-literal=DB_HOST=your_db_host \
  --from-literal=DB_PORT=5432 \
  -n <NAMESPACE>

# Nexus Secret for pulling images (required)
kubectl create secret docker-registry nexus-secret \
  --docker-server=127.0.0.1:30085 \
  --docker-username=your_nexus_user \
  --docker-password=your_nexus_password \
  -n <NAMESPACE>
```

### 2. Deploy Resources in Order

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create PVC (if storage is needed)
kubectl apply -f pvc.yaml

# 3. Deploy the application
kubectl apply -f deployment.yaml

# 4. Create the service
kubectl apply -f service.yaml

# 5. Create the ingress
kubectl apply -f ingress.yaml
```

### 3. Verify Deployment

```bash
# Check deployment status
kubectl get deployments -n <NAMESPACE>

# Check pod status
kubectl get pods -n <NAMESPACE>

# Check service
kubectl get svc -n <NAMESPACE>

# Check ingress
kubectl get ingress -n <NAMESPACE>

# View pod logs
kubectl logs -f deployment/<APP_NAME>-deployment -n <NAMESPACE>
```

## 🔍 Health Checks

The deployment includes:

- **Readiness Probe**: Checks `/health` endpoint every 10s (starts after 10s)
- **Liveness Probe**: Checks `/health` endpoint every 30s (starts after 30s)

Ensure your application has a `/health` endpoint that returns HTTP 200 when healthy.

## 💾 Persistent Storage

The deployment is configured with:
- **Volume**: Mounted at `/app/data`
- **Storage Class**: `local-path`
- **Size**: 1Gi
- **Access Mode**: ReadWriteOnce

If your application doesn't need persistent storage, you can:
1. Remove the `volumeMounts` section from `deployment.yaml`
2. Remove the `volumes` section from `deployment.yaml`
3. Skip deploying `pvc.yaml`

## 🌐 Accessing the Application

After deployment:

### Internal (within cluster):
```
http://<APP_NAME>-service.<NAMESPACE>.svc.cluster.local:<APP_PORT>
```

### External (via ingress):
```
http://<APP_DOMAIN>.imcc.com
```

## 📊 Resource Limits

The deployment includes resource management:

**Requests** (minimum guaranteed):
- CPU: 500m (0.5 cores)
- Memory: 512Mi

**Limits** (maximum allowed):
- CPU: 1 (1 core)
- Memory: 1Gi

Adjust these values based on your application's requirements.

## 🔄 Update Deployment

To update the application:

```bash
# Apply updated deployment
kubectl apply -f deployment.yaml

# Check rollout status
kubectl rollout status deployment/<APP_NAME>-deployment -n <NAMESPACE>

# Rollback if needed
kubectl rollout undo deployment/<APP_NAME>-deployment -n <NAMESPACE>
```

## 🛠️ Troubleshooting

### Pod not starting?
```bash
# Describe pod for events
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# Check pod logs
kubectl logs <POD_NAME> -n <NAMESPACE>
```

### Image pull failures?
- Verify `nexus-secret` exists and has correct credentials
- Check if the image exists in the registry: `127.0.0.1:30085/<PROJECT_NAMESPACE>/<APP_NAME>:<TAG>`

### Service not accessible?
- Verify the service selector matches deployment labels
- Check if pod is in `Running` state
- Ensure the port configuration matches your application

### Ingress not working?
- Verify nginx ingress controller is installed
- Check ingress configuration: `kubectl describe ingress <APP_NAME>-ingress -n <NAMESPACE>`
- Ensure DNS is configured for `<APP_DOMAIN>.imcc.com`

## 📝 Notes

- The `nexus-secret` name is fixed and should **NOT** be changed (as noted in deployment.yaml)
- All environment variables from secrets/configmaps are injected into the container
- The deployment uses a single replica by default; scale as needed
- DEBUG is set to "0" in production

## 🔗 Related Files

- **Jenkinsfile**: CI/CD pipeline configuration (in project root)
- **Dockerfile**: Container image definition (in project root)
- **sonar-project.properties**: SonarQube configuration (in project root)
