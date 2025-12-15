@echo off
REM ========================================
REM Windows Deployment Script for Kubernetes
REM ========================================

setlocal enabledelayedexpansion

set NAMESPACE=chatbot-prod
set APP_NAME=sohamrepo-chatbot

echo ==========================================
echo Deploying %APP_NAME% to Kubernetes
echo Namespace: %NAMESPACE%
echo ==========================================

REM Check if namespace exists
kubectl get namespace %NAMESPACE% >nul 2>&1
if errorlevel 1 (
    echo Error: Namespace '%NAMESPACE%' does not exist!
    echo Please run setup.bat first
    pause
    exit /b 1
)

REM Check if nexus-secret exists
kubectl get secret nexus-secret -n %NAMESPACE% >nul 2>&1
if errorlevel 1 (
    echo Error: nexus-secret not found!
    echo Please run setup.bat first
    pause
    exit /b 1
)

echo.
echo Choose deployment type:
echo   1) Full deployment (with database + storage)
echo   2) No storage (database only)
echo   3) Simple (no database, no storage)
echo.
set /p CHOICE="Enter choice [1-3]: "

if "%CHOICE%"=="1" (
    set DEPLOYMENT_FILE=deployment.yaml
    set NEEDS_PVC=true
    echo Using: Full deployment with database and storage
) else if "%CHOICE%"=="2" (
    set DEPLOYMENT_FILE=deployment-no-storage.yaml
    set NEEDS_PVC=false
    echo Using: Deployment with database, no storage
) else if "%CHOICE%"=="3" (
    set DEPLOYMENT_FILE=deployment-simple.yaml
    set NEEDS_PVC=false
    echo Using: Simple deployment
) else (
    echo Invalid choice!
    pause
    exit /b 1
)

echo.
echo Deploying resources...

if "%NEEDS_PVC%"=="true" (
    echo   -^> Creating PersistentVolumeClaim...
    kubectl apply -f pvc.yaml
)

echo   -^> Creating deployment...
kubectl apply -f %DEPLOYMENT_FILE%

echo   -^> Creating service...
kubectl apply -f service.yaml

echo   -^> Creating ingress...
kubectl apply -f ingress.yaml

echo.
echo Resources applied successfully!

echo.
echo Waiting for deployment to be ready...
kubectl rollout status deployment/%APP_NAME%-deployment -n %NAMESPACE% --timeout=5m

echo.
echo ==========================================
echo Deployment completed successfully!
echo ==========================================
echo.
echo Pod status:
kubectl get pods -n %NAMESPACE% -l app=%APP_NAME%

echo.
echo Service details:
kubectl get svc -n %NAMESPACE% -l app=%APP_NAME%

echo.
echo Ingress details:
kubectl get ingress -n %NAMESPACE%

echo.
echo ==========================================
echo Application Access:
echo ==========================================
echo   Internal: http://%APP_NAME%-service.%NAMESPACE%.svc.cluster.local:8501
echo   External: http://chatbot.imcc.com
echo.
echo To view logs:
echo   kubectl logs -f deployment/%APP_NAME%-deployment -n %NAMESPACE%
echo.

pause
