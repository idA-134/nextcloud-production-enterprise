# GitHub Upload Guide
# Anleitung zum Hochladen des Production-Ordners auf GitHub

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Nextcloud Production → GitHub Upload" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Schritt 1: GitHub Repository erstellen" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host "1. Gehen Sie zu: https://github.com/new"
Write-Host "2. Repository Name: z.B. 'nextcloud-production'"
Write-Host "3. Description: 'Enterprise Nextcloud setup for 500+ users'"
Write-Host "4. Private/Public wählen (EMPFEHLUNG: Private!)"
Write-Host "5. NICHT initialisieren mit README/gitignore/License"
Write-Host "6. Klicken Sie auf 'Create repository'"
Write-Host ""
Read-Host "Drücken Sie Enter wenn Sie das Repository erstellt haben"

Write-Host ""
Write-Host "Schritt 2: Git-Befehle ausführen" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow
Write-Host ""

# Prüfen ob Git installiert ist
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Git ist installiert: $gitVersion" -ForegroundColor Green
    } else {
        throw "Git nicht gefunden"
    }
} catch {
    Write-Host "✗ Git ist nicht installiert!" -ForegroundColor Red
    Write-Host "Bitte installieren Sie Git: https://git-scm.com/download/win"
    exit 1
}

Write-Host ""
Write-Host "Kopieren Sie diese Befehle und führen Sie sie aus:" -ForegroundColor Cyan
Write-Host ""

# Repository-URL vom Benutzer abfragen
$repoUrl = Read-Host "Geben Sie Ihre GitHub Repository URL ein (z.B. https://github.com/IhrName/nextcloud-production.git)"

Write-Host ""
Write-Host "--- BEFEHLE ZUM KOPIEREN ---" -ForegroundColor Green
Write-Host ""

$commands = @"
# In den production-Ordner wechseln
cd production

# Git Repository initialisieren
git init

# Alle Dateien hinzufügen
git add .

# Ersten Commit erstellen
git commit -m "Initial commit: Nextcloud Production Setup"

# Standard-Branch zu main umbenennen
git branch -M main

# Remote Repository hinzufügen
git remote add origin $repoUrl

# Zu GitHub hochladen
git push -u origin main
"@

Write-Host $commands -ForegroundColor White
Write-Host ""
Write-Host "--- ENDE DER BEFEHLE ---" -ForegroundColor Green
Write-Host ""

Write-Host "WICHTIG:" -ForegroundColor Red
Write-Host "- Die .env Datei wird NICHT hochgeladen (steht in .gitignore)" -ForegroundColor Yellow
Write-Host "- Backups werden NICHT hochgeladen" -ForegroundColor Yellow
Write-Host "- SSL-Zertifikate werden NICHT hochgeladen" -ForegroundColor Yellow
Write-Host ""

Write-Host "Möchten Sie die Befehle jetzt automatisch ausführen? (j/n): " -NoNewline -ForegroundColor Cyan
$answer = Read-Host

if ($answer -eq "j" -or $answer -eq "J" -or $answer -eq "y" -or $answer -eq "Y") {
    Write-Host ""
    Write-Host "Führe Git-Befehle aus..." -ForegroundColor Green
    Write-Host ""
    
    try {
        # In production-Ordner wechseln
        Set-Location -Path "." -ErrorAction Stop
        
        # Git initialisieren
        Write-Host "→ Initialisiere Git Repository..." -ForegroundColor Cyan
        git init
        
        # Dateien hinzufügen
        Write-Host "→ Füge Dateien hinzu..." -ForegroundColor Cyan
        git add .
        
        # Ersten Commit
        Write-Host "→ Erstelle ersten Commit..." -ForegroundColor Cyan
        git commit -m "Initial commit: Nextcloud Production Setup for 500+ users"
        
        # Branch umbenennen
        Write-Host "→ Benenne Branch zu 'main' um..." -ForegroundColor Cyan
        git branch -M main
        
        # Remote hinzufügen
        Write-Host "→ Füge Remote Repository hinzu..." -ForegroundColor Cyan
        git remote add origin $repoUrl
        
        # Push zu GitHub
        Write-Host "→ Lade zu GitHub hoch..." -ForegroundColor Cyan
        git push -u origin main
        
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Green
        Write-Host "   ✓ Erfolgreich auf GitHub hochgeladen!" -ForegroundColor Green
        Write-Host "================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ihr Repository: $repoUrl" -ForegroundColor White
        Write-Host ""
        
    } catch {
        Write-Host ""
        Write-Host "✗ Fehler beim Hochladen!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "Bitte führen Sie die Befehle manuell aus (siehe oben)" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Bitte führen Sie die Befehle manuell aus (siehe oben)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Nächste Schritte nach dem Upload:" -ForegroundColor Cyan
Write-Host "1. Erstellen Sie eine .env.example Datei auf GitHub (als Template)"
Write-Host "2. Aktualisieren Sie die README_GITHUB.md auf GitHub"
Write-Host "3. Fügen Sie ein LICENSE File hinzu (optional)"
Write-Host "4. Erstellen Sie ein CHANGELOG.md (optional)"
Write-Host ""
