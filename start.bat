@echo off
setlocal enabledelayedexpansion
title Multi-Exchange Crypto Trading Terminal

cd /d "%~dp0"

echo ============================================================
echo   MULTI-EXCHANGE CRYPTO TRADING TERMINAL (PHASE-2)
echo   Delta Exchange India ^& CoinSwitch PRO
echo ============================================================
echo.

REM 1. Detect or Create Virtual Environment
if not exist ".venv\Scripts\python.exe" (
    echo [INFO] Virtual environment not detected. Creating fresh .venv...
    where python >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Python is not installed or not in PATH!
        echo Please install Python 3.11+ and add it to PATH.
        echo.
        pause
        exit /b 1
    )
    python -m venv .venv
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo [INFO] Virtual environment created successfully.
    echo [INFO] Installing required dependencies from backend\requirements.txt...
    .venv\Scripts\python.exe -m pip install --upgrade pip
    .venv\Scripts\python.exe -m pip install -r backend\requirements.txt
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Failed to install dependencies.
        pause
        exit /b 1
    )
)

REM 2. Set PYTHONPATH and Environment Variables
set PYTHONPATH=%CD%\backend
set MODE=paper
set LIVE_TRADING_ENABLED=false

echo [INFO] Environment: PAPER TRADING (Safe Mode - No Real Capital at Risk)
echo [INFO] Live Trading Safety Gate: DISABLED by default
echo [INFO] Backend Directory: %PYTHONPATH%
echo.

echo ============================================================
echo   STARTING BACKEND SERVER & FRONTEND TERMINAL
echo   URL: http://127.0.0.1:8000
echo ============================================================
echo.
echo Launching default web browser...
start "" "http://127.0.0.1:8000"

echo Running Uvicorn ASGI Server on port 8000...
echo Keep this window open. Press Ctrl+C to terminate.
echo.

.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --app-dir backend --log-level info

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Server exited with an error code: %ERRORLEVEL%
    pause
)

echo.
echo ============================================================
echo   TRADING TERMINAL TERMINATED GRACEFULLY
echo ============================================================
pause
