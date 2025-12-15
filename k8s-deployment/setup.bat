@echo off
REM ========================================
REM Windows Setup Script for Kubernetes
REM ========================================

setlocal enabledelayedexpansion

set NAMESPACE=chatbot-prod
set APP_NAME=sohamrepo-chatbot

echo ==========================================
echo Setting up Kubernetes secrets and configs
echo Namespace: %NAMESPACE%
echo ==========================================

echo.
echo Creating namespace...
kubectl apply -f namespace.yaml

REM ========================================
REM Create Nexus Registry Secret
REM ========================================
echo.
echo Creating Nexus registry secret...
set /p NEXUS_USER="Enter Nexus username: "
set /p NEXUS_PASS="Enter Nexus password: "

kubectl create secret docker-registry nexus-secret ^
  --docker-server=127.0.0.1:30085 ^
  --docker-username=%NEXUS_USER% ^
  --docker-password=%NEXUS_PASS% ^
  --namespace=%NAMESPACE% ^
  --dry-run=client -o yaml | kubectl apply -f -

echo Nexus secret created

REM ========================================
REM Create Database Secrets (Optional)
REM ========================================
echo.
set /p NEED_DB="Does your app need database connectivity? (y/n): "

if /i "%NEED_DB%"=="y" (
    echo.
    echo Creating database credentials...
    set /p DB_USER="Enter DB username: "
    set /p DB_PASS="Enter DB password: "
    set /p DB_NAME="Enter DB name: "
    
    kubectl create secret generic db-secret ^
      --from-literal=DB_USER=!DB_USER! ^
      --from-literal=DB_PASSWORD=!DB_PASS! ^
      --from-literal=DB_NAME=!DB_NAME! ^
      --namespace=%NAMESPACE% ^
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo Database secret created
    
    echo.
    echo Creating database config...
    set /p DB_HOST="Enter DB host: "
    set /p DB_PORT="Enter DB port (default: 5432): "
    if "%DB_PORT%"=="" set DB_PORT=5432
    
    kubectl create configmap db-config ^
      --from-literal=DB_HOST=!DB_HOST! ^
      --from-literal=DB_PORT=!DB_PORT! ^
      --namespace=%NAMESPACE% ^
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo Database config created
) else (
    echo Skipping database setup. Use deployment-simple.yaml for deployment.
)

echo.
echo ==========================================
echo Setup Complete! Verifying...
echo ==========================================
echo.
echo Secrets in namespace '%NAMESPACE%':
kubectl get secrets -n %NAMESPACE%

echo.
echo ConfigMaps in namespace '%NAMESPACE%':
kubectl get configmaps -n %NAMESPACE%

echo.
echo ==========================================
echo Setup completed successfully!
echo ==========================================
echo.
echo Next steps:
echo   1. Run: deploy.bat to deploy the application
echo   2. Or manually: kubectl apply -f deployment.yaml
echo.

pause
