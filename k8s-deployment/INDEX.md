# CI/CD Pipeline - Complete File Index

This directory contains all files needed for deploying the chatbot application to Kubernetes.

## 📁 Directory Structure

```
k8s-deployment/
│
├── 📋 Documentation
│   ├── README.md                      # Comprehensive deployment guide
│   ├── QUICK_START.md                 # Quick configuration checklist
│   ├── kubectl-commands.txt           # kubectl command reference
│   └── INDEX.md                       # This file
│
├── 🎯 Core Kubernetes Files
│   ├── namespace.yaml                 # Namespace configuration
│   ├── deployment.yaml                # Full deployment (DB + Storage)
│   ├── service.yaml                   # ClusterIP service
│   ├── pvc.yaml                       # PersistentVolumeClaim (1Gi)
│   └── ingress.yaml                   # Nginx ingress
│
├── 🔄 Alternative Deployments
│   ├── deployment-simple.yaml         # No DB, no storage
│   └── deployment-no-storage.yaml     # DB only, no storage
│
├── 🐧 Linux/Mac Scripts (.sh)
│   ├── setup.sh                       # Create secrets & configmaps
│   ├── deploy.sh                      # Deploy application
│   ├── verify.sh                      # Verify deployment
│   └── cleanup.sh                     # Remove all resources
│
└── 🪟 Windows Scripts (.bat)
    ├── setup.bat                      # Create secrets & configmaps
    ├── deploy.bat                     # Deploy application
    └── cleanup.bat                    # Remove all resources
```

## 🎯 Quick Start

### For Linux/Mac/WSL:
```bash
chmod +x *.sh
./setup.sh    # First time setup
./deploy.sh   # Deploy
./verify.sh   # Verify
```

### For Windows (CMD/PowerShell):
```cmd
setup.bat     # First time setup
deploy.bat    # Deploy
verify.bat    # Verify (use kubectl commands from kubectl-commands.txt)
```

## 📖 File Descriptions

### Documentation Files

| File | Description |
|------|-------------|
| `README.md` | Detailed deployment guide with troubleshooting |
| `QUICK_START.md` | Step-by-step configuration checklist |
| `kubectl-commands.txt` | Common kubectl commands reference |
| `INDEX.md` | This file - directory structure overview |

### Kubernetes Configuration Files

| File | Purpose | Required? |
|------|---------|-----------|
| `namespace.yaml` | Creates `chatbot-prod` namespace | ✅ Yes |
| `deployment.yaml` | Main app deployment (DB + Storage) | ✅ Yes (choose one) |
| `deployment-simple.yaml` | Simplified (no DB, no storage) | Alternative |
| `deployment-no-storage.yaml` | Database but no storage | Alternative |
| `service.yaml` | Internal ClusterIP service | ✅ Yes |
| `pvc.yaml` | 1Gi persistent storage | Only if using storage |
| `ingress.yaml` | External HTTP access | Yes (if external access needed) |

### Shell Scripts (Linux/Mac)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup.sh` | Create secrets/configmaps | First time setup |
| `deploy.sh` | Deploy application | Every deployment |
| `verify.sh` | Check deployment status | After deployment |
| `cleanup.sh` | Remove all resources | Cleanup/teardown |

### Batch Scripts (Windows)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup.bat` | Create secrets/configmaps | First time setup |
| `deploy.bat` | Deploy application | Every deployment |
| `cleanup.bat` | Remove all resources | Cleanup/teardown |

## 🔑 Configuration Summary

All files are pre-configured with these values:

- **Namespace**: `chatbot-prod`
- **App Name**: `sohamrepo-chatbot`
- **Port**: `8501` (Streamlit)
- **Image**: `127.0.0.1:30085/sohamrepo/sohamrepo-chatbot:latest`
- **Domain**: `chatbot.imcc.com`

## 🚀 Deployment Options

### Option 1: Full Deployment (Database + Storage)
```bash
./setup.sh          # Create all secrets
./deploy.sh         # Choose option 1
```
Uses: `deployment.yaml` + `pvc.yaml`

### Option 2: Database Only (No Storage)
```bash
./setup.sh          # Create all secrets
./deploy.sh         # Choose option 2
```
Uses: `deployment-no-storage.yaml`

### Option 3: Simple (Stateless)
```bash
./setup.sh          # Create Nexus secret only
./deploy.sh         # Choose option 3
```
Uses: `deployment-simple.yaml`

## 📊 Resource Requirements

### What Each Deployment Needs:

| Deployment Type | Nexus Secret | DB Secret | DB Config | PVC |
|----------------|--------------|-----------|-----------|-----|
| Full (`deployment.yaml`) | ✅ | ✅ | ✅ | ✅ |
| No Storage (`deployment-no-storage.yaml`) | ✅ | ✅ | ✅ | ❌ |
| Simple (`deployment-simple.yaml`) | ✅ | ❌ | ❌ | ❌ |

## 🔍 Verification

After deployment, verify with:

**Linux/Mac:**
```bash
./verify.sh
```

**Windows/Manual:**
```bash
kubectl get all -n chatbot-prod
kubectl get pods -n chatbot-prod -l app=sohamrepo-chatbot
kubectl logs -f deployment/sohamrepo-chatbot-deployment -n chatbot-prod
```

## 🌐 Access Points

After successful deployment:

- **Internal** (within cluster):  
  `http://sohamrepo-chatbot-service.chatbot-prod.svc.cluster.local:8501`

- **External** (via ingress):  
  `http://chatbot.imcc.com`

- **Port Forward** (local testing):  
  `kubectl port-forward svc/sohamrepo-chatbot-service 8501:8501 -n chatbot-prod`  
  Then access: `http://localhost:8501`

## 🧹 Cleanup

To remove all resources:

**Linux/Mac:**
```bash
./cleanup.sh
```

**Windows:**
```cmd
cleanup.bat
```

**Manual:**
```bash
kubectl delete all -l app=sohamrepo-chatbot -n chatbot-prod
kubectl delete namespace chatbot-prod
```

## 📚 Related Files

- **Root Directory**:
  - `Jenkinsfile` - Jenkins CI/CD pipeline
  - `Dockerfile` - Container image definition
  - `sonar-project.properties` - SonarQube configuration

## 💡 Tips

1. **First deployment?** Start with `deployment-simple.yaml` to test
2. **Need database?** Use `setup.sh` to create all secrets
3. **Troubleshooting?** Check `kubectl-commands.txt` for debugging commands
4. **Windows user?** Use `.bat` scripts instead of `.sh`
5. **Errors?** Run `verify.sh` to diagnose issues

## 🆘 Support

For detailed information, see:
- Deployment guide: `README.md`
- Quick start: `QUICK_START.md`
- Commands: `kubectl-commands.txt`
- PDF reference: `../CI_CD Pipeline Reference Guide.pdf`
