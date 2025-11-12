@echo off
REM Quick GitHub Upload Script
REM Vereinfachtes Skript für Windows

echo.
echo ================================================
echo    GitHub Upload - Quick Start
echo ================================================
echo.

REM Git prüfen
git --version >nul 2>&1
if errorlevel 1 (
    echo [FEHLER] Git ist nicht installiert!
    echo Bitte installieren Sie Git: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [OK] Git ist installiert
echo.

REM Repository URL abfragen
set /p REPO_URL="Geben Sie Ihre GitHub Repository URL ein: "

if "%REPO_URL%"=="" (
    echo [FEHLER] Keine URL eingegeben!
    pause
    exit /b 1
)

echo.
echo Starte Upload zu: %REPO_URL%
echo.

REM Git-Befehle ausführen
echo [1/6] Initialisiere Git Repository...
git init
if errorlevel 1 goto :error

echo [2/6] Fuege Dateien hinzu...
git add .
if errorlevel 1 goto :error

echo [3/6] Erstelle Commit...
git commit -m "Initial commit: Nextcloud Production Setup for 500+ users"
if errorlevel 1 goto :error

echo [4/6] Benenne Branch um...
git branch -M main
if errorlevel 1 goto :error

echo [5/6] Verbinde mit GitHub...
git remote add origin %REPO_URL%
if errorlevel 1 goto :error

echo [6/6] Lade zu GitHub hoch...
git push -u origin main
if errorlevel 1 goto :error

echo.
echo ================================================
echo    Upload erfolgreich!
echo ================================================
echo.
echo Ihr Repository: %REPO_URL%
echo.
pause
exit /b 0

:error
echo.
echo [FEHLER] Upload fehlgeschlagen!
echo Bitte siehe GITHUB_UPLOAD_ANLEITUNG.md fuer Details
echo.
pause
exit /b 1
