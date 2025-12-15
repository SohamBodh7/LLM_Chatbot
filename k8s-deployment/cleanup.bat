@echo off
REM ========================================
REM Windows Cleanup Script for Kubernetes
REM ========================================

setlocal enabledelayedexpansion

set NAMESPACE=chatbot-prod
set APP_NAME=sohamrepo-chatbot

echo ==========================================
echo WARNING: CLEANUP SCRIPT
echo This will DELETE all resources for %APP_NAME%
echo Namespace: %NAMESPACE%
echo ==========================================
echo.
echo This will delete:
echo   - Deployment
echo   - Service
echo   - Ingress
echo   - PersistentVolumeClaim
echo   - Secrets (optional)
echo   - ConfigMaps (optional)
echo   - Namespace (optional)
echo.

set /p CONFIRM="Are you sure you want to continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo Cleanup cancelled.
    pause
    exit /b 0
)

REM ========================================
REM Delete Resources
REM ========================================
echo.
echo Deleting deployment resources...

REM Delete ingress
kubectl get ingress %APP_NAME%-ingress -n %NAMESPACE% >nul 2>&1
if not errorlevel 1 (
    echo   -^> Deleting ingress...
    kubectl delete ingress %APP_NAME%-ingress -n %NAMESPACE%
    echo   ✓ Ingress deleted
)

REM Delete service
kubectl get svc %APP_NAME%-service -n %NAMESPACE% >nul 2>&1
if not errorlevel 1 (
    echo   -^> Deleting service...
    kubectl delete svc %APP_NAME%-service -n %NAMESPACE%
    echo   ✓ Service deleted
)

REM Delete deployment
kubectl get deployment %APP_NAME%-deployment -n %NAMESPACE% >nul 2>&1
if not errorlevel 1 (
    echo   -^> Deleting deployment...
    kubectl delete deployment %APP_NAME%-deployment -n %NAMESPACE%
    echo   ✓ Deployment deleted
)

REM Delete PVC
kubectl get pvc app-pvc -n %NAMESPACE% >nul 2>&1
if not errorlevel 1 (
    echo   -^> Deleting PVC...
    kubectl delete pvc app-pvc -n %NAMESPACE%
    echo   ✓ PVC deleted
)

REM ========================================
REM Optional: Delete Secrets and ConfigMaps
REM ========================================
echo.
set /p DELETE_SECRETS="Delete secrets and configmaps? (y/n): "

if /i "%DELETE_SECRETS%"=="y" (
    kubectl get secret db-secret -n %NAMESPACE% >nul 2>&1
    if not errorlevel 1 (
        echo   -^> Deleting db-secret...
        kubectl delete secret db-secret -n %NAMESPACE%
    )
    
    kubectl get configmap db-config -n %NAMESPACE% >nul 2>&1
    if not errorlevel 1 (
        echo   -^> Deleting db-config...
        kubectl delete configmap db-config -n %NAMESPACE%
    )
    
    kubectl get secret nexus-secret -n %NAMESPACE% >nul 2>&1
    if not errorlevel 1 (
        echo   -^> Deleting nexus-secret...
        kubectl delete secret nexus-secret -n %NAMESPACE%
    )
    
    echo   ✓ Secrets and configmaps deleted
)

REM ========================================
REM Optional: Delete Namespace
REM ========================================
echo.
set /p DELETE_NAMESPACE="Delete entire namespace '%NAMESPACE%'? (y/n): "

if /i "%DELETE_NAMESPACE%"=="y" (
    echo   -^> Deleting namespace...
    kubectl delete namespace %NAMESPACE%
    echo   ✓ Namespace deleted
)

REM ========================================
REM Verify Cleanup
REM ========================================
echo.
echo ==========================================
echo Cleanup Complete!
echo ==========================================
echo.

kubectl get namespace %NAMESPACE% >nul 2>&1
if not errorlevel 1 (
    echo Remaining resources in namespace '%NAMESPACE%':
    kubectl get all -n %NAMESPACE%
) else (
    echo Namespace '%NAMESPACE%' has been deleted.
)

echo.
echo To redeploy:
echo   1. Run: setup.bat
echo   2. Run: deploy.bat
echo.

pause
