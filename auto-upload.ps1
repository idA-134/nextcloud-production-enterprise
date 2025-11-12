# ================================================
# Nextcloud Production - Automatischer GitHub Upload
# Vollautomatisches Skript
# ================================================

param(
    [string]$RepoUrl = "",
    [string]$RepoName = "nextcloud-production-enterprise",
    [switch]$CreateRepo = $false
)

$ErrorActionPreference = "Stop"

# Farben
function Write-Success { param([string]$msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Error-Msg { param([string]$msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "ℹ $msg" -ForegroundColor Cyan }
function Write-Warning-Msg { param([string]$msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Step { param([string]$msg) Write-Host "`n═══ $msg ═══" -ForegroundColor Magenta }

Clear-Host
Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Nextcloud Production → GitHub Upload" -ForegroundColor Cyan
Write-Host "   Vollautomatisches Upload-Skript" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ========================================
# Schritt 1: Voraussetzungen prüfen
# ========================================
Write-Step "1/7 Prüfe Voraussetzungen"

# Git prüfen
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Git installiert: $gitVersion"
    } else {
        throw "Git nicht gefunden"
    }
} catch {
    Write-Error-Msg "Git ist nicht installiert!"
    Write-Host ""
    Write-Host "Bitte installieren Sie Git:" -ForegroundColor Yellow
    Write-Host "https://git-scm.com/download/win" -ForegroundColor White
    Write-Host ""
    Read-Host "Drücken Sie Enter zum Beenden"
    exit 1
}

# GitHub CLI prüfen (optional)
$hasGH = $false
try {
    $ghVersion = gh --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "GitHub CLI installiert: $($ghVersion.Split("`n")[0])"
        $hasGH = $true
    }
} catch {
    Write-Warning-Msg "GitHub CLI nicht installiert (optional)"
    Write-Info "Für automatische Repo-Erstellung: https://cli.github.com/"
}

# Prüfen ob bereits Git-Repo
if (Test-Path ".git") {
    Write-Warning-Msg "Git-Repository existiert bereits!"
    $overwrite = Read-Host "Möchten Sie es neu initialisieren? (j/n)"
    if ($overwrite -eq "j" -or $overwrite -eq "J") {
        Remove-Item -Recurse -Force ".git"
        Write-Success "Altes Repository entfernt"
    } else {
        Write-Error-Msg "Abgebrochen"
        exit 1
    }
}

# ========================================
# Schritt 2: Repository URL ermitteln
# ========================================
Write-Step "2/7 Repository-Konfiguration"

if ($RepoUrl -eq "") {
    Write-Host ""
    Write-Info "Sie haben 2 Optionen:"
    Write-Host "  1) Automatisch neues Repository erstellen (benötigt GitHub CLI)" -ForegroundColor White
    Write-Host "  2) Manuell - Repository URL eingeben" -ForegroundColor White
    Write-Host ""
    
    if ($hasGH) {
        $choice = Read-Host "Wählen Sie Option (1 oder 2)"
        
        if ($choice -eq "1") {
            Write-Info "Erstelle GitHub Repository automatisch..."
            
            # GitHub Username ermitteln
            try {
                $ghUser = (gh api user --jq .login) 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning-Msg "Nicht bei GitHub angemeldet"
                    Write-Info "Führe GitHub Login durch..."
                    gh auth login
                    $ghUser = (gh api user --jq .login)
                }
                Write-Success "GitHub User: $ghUser"
            } catch {
                Write-Error-Msg "GitHub-Authentifizierung fehlgeschlagen"
                exit 1
            }
            
            # Repository erstellen
            Write-Info "Erstelle Repository: $RepoName"
            
            $visibility = Read-Host "Repository Sichtbarkeit (private/public) [private]"
            if ($visibility -eq "") { $visibility = "private" }
            
            try {
                gh repo create $RepoName `
                    --description "Enterprise Nextcloud Setup für 500+ Benutzer mit Docker Compose, Talk, OnlyOffice" `
                    --$visibility `
                    --confirm 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Repository erstellt!"
                    $RepoUrl = "https://github.com/$ghUser/$RepoName.git"
                } else {
                    Write-Warning-Msg "Repository existiert möglicherweise bereits"
                    $RepoUrl = "https://github.com/$ghUser/$RepoName.git"
                }
            } catch {
                Write-Error-Msg "Fehler beim Erstellen: $_"
                exit 1
            }
        } else {
            $RepoUrl = Read-Host "Geben Sie die GitHub Repository URL ein"
        }
    } else {
        $RepoUrl = Read-Host "Geben Sie die GitHub Repository URL ein"
    }
}

if ($RepoUrl -eq "" -or $RepoUrl -notmatch "github\.com") {
    Write-Error-Msg "Ungültige Repository URL!"
    exit 1
}

Write-Success "Repository URL: $RepoUrl"

# ========================================
# Schritt 3: Dateien vorbereiten
# ========================================
Write-Step "3/7 Bereite Dateien vor"

# Prüfen ob .env existiert und .env.example erstellen falls nötig
if (Test-Path ".env") {
    Write-Success ".env Datei gefunden (wird nicht hochgeladen)"
    
    if (-not (Test-Path ".env.example")) {
        Write-Info "Erstelle .env.example aus .env..."
        $envContent = Get-Content ".env" -Raw
        # Passwörter maskieren
        $envContent = $envContent -replace '(PASSWORD|SECRET|JWT)=.*', '$1=AENDERN_SIE_DIESEN_WERT'
        Set-Content ".env.example" -Value $envContent
        Write-Success ".env.example erstellt"
    }
}

# Prüfen ob .gitignore existiert
if (-not (Test-Path ".gitignore")) {
    Write-Warning-Msg ".gitignore nicht gefunden - erstelle Standardversion"
    
    $gitignoreContent = @"
# Umgebungsvariablen mit sensiblen Daten
.env
.env.local

# Backups
backups/
*.sql
*.sql.gz
*.tar.gz

# SSL-Zertifikate
ssl/
*.pem
*.key
*.crt

# Logs
*.log
logs/

# Docker Volumes
volumes/

# Temporäre Dateien
tmp/
temp/
*.tmp

# Betriebssystem
.DS_Store
Thumbs.db
desktop.ini

# Editor
.vscode/
.idea/
*.swp
*.swo
"@
    
    Set-Content ".gitignore" -Value $gitignoreContent
    Write-Success ".gitignore erstellt"
}

Write-Success "Dateien vorbereitet"

# ========================================
# Schritt 4: Git initialisieren
# ========================================
Write-Step "4/7 Initialisiere Git Repository"

try {
    git init 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Git Repository initialisiert"
    } else {
        throw "Git init fehlgeschlagen"
    }
} catch {
    Write-Error-Msg "Fehler beim Initialisieren: $_"
    exit 1
}

# Git-Konfiguration prüfen
$gitUser = git config user.name 2>&1
$gitEmail = git config user.email 2>&1

if ($gitUser -eq "" -or $gitEmail -eq "") {
    Write-Warning-Msg "Git-Konfiguration fehlt"
    Write-Host ""
    $userName = Read-Host "Ihr Name"
    $userEmail = Read-Host "Ihre E-Mail"
    
    git config user.name "$userName"
    git config user.email "$userEmail"
    Write-Success "Git-Konfiguration gesetzt"
}

# ========================================
# Schritt 5: Dateien hinzufügen
# ========================================
Write-Step "5/7 Füge Dateien hinzu"

try {
    git add . 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $fileCount = (git diff --cached --name-only | Measure-Object).Count
        Write-Success "$fileCount Dateien hinzugefügt"
        
        # Zeige hinzugefügte Dateien
        Write-Info "Folgende Dateien werden hochgeladen:"
        git diff --cached --name-only | ForEach-Object {
            Write-Host "  + $_" -ForegroundColor Gray
        }
    } else {
        throw "Git add fehlgeschlagen"
    }
} catch {
    Write-Error-Msg "Fehler beim Hinzufügen: $_"
    exit 1
}

# ========================================
# Schritt 6: Commit erstellen
# ========================================
Write-Step "6/7 Erstelle Commit"

$commitMessage = "Initial commit: Nextcloud Production Setup

- Docker Compose Setup für 500+ Benutzer
- Nextcloud mit Talk (Chat/Video/Audio)
- OnlyOffice Document Server
- PostgreSQL 15 (Performance-optimiert)
- Redis Caching
- Nginx Reverse Proxy mit SSL
- Automatische Backups
- Health Monitoring
- TURN/STUN Server für WebRTC
- Vollständige Dokumentation

Enterprise-ready Setup mit Sicherheits- und Performance-Optimierungen."

try {
    git commit -m "$commitMessage" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Commit erstellt"
    } else {
        throw "Git commit fehlgeschlagen"
    }
} catch {
    Write-Error-Msg "Fehler beim Commit: $_"
    exit 1
}

# Branch umbenennen
try {
    git branch -M main 2>&1 | Out-Null
    Write-Success "Branch 'main' erstellt"
} catch {
    Write-Warning-Msg "Branch-Umbenennung übersprungen"
}

# ========================================
# Schritt 7: Zu GitHub hochladen
# ========================================
Write-Step "7/7 Lade zu GitHub hoch"

try {
    # Remote hinzufügen
    git remote add origin $RepoUrl 2>&1 | Out-Null
    Write-Success "Remote 'origin' hinzugefügt"
    
    # Push zu GitHub
    Write-Info "Upload läuft... (kann einige Sekunden dauern)"
    Write-Host ""
    
    $pushOutput = git push -u origin main 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Upload erfolgreich abgeschlossen!"
    } else {
        # Falls Repository nicht leer ist, force push anbieten
        if ($pushOutput -match "rejected|non-fast-forward") {
            Write-Warning-Msg "Repository ist nicht leer"
            $force = Read-Host "Force Push durchführen? (überschreibt Remote) (j/n)"
            
            if ($force -eq "j" -or $force -eq "J") {
                git push -u origin main --force 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Force Push erfolgreich!"
                } else {
                    throw "Force Push fehlgeschlagen"
                }
            } else {
                throw "Upload abgebrochen"
            }
        } else {
            throw "Push fehlgeschlagen: $pushOutput"
        }
    }
} catch {
    Write-Error-Msg "Fehler beim Upload: $_"
    Write-Host ""
    Write-Warning-Msg "Mögliche Lösungen:"
    Write-Host "1. Prüfen Sie Ihre GitHub-Zugangsdaten" -ForegroundColor Yellow
    Write-Host "2. Prüfen Sie die Repository-URL" -ForegroundColor Yellow
    Write-Host "3. Stellen Sie sicher, dass das Repository leer ist" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Drücken Sie Enter zum Beenden"
    exit 1
}

# ========================================
# Erfolgsmeldung
# ========================================
Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   ✓ Upload erfolgreich abgeschlossen!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Write-Info "Ihr Repository:"
Write-Host "  $($RepoUrl -replace '\.git$', '')" -ForegroundColor White
Write-Host ""

Write-Info "Nächste Schritte:"
Write-Host "  1. Repository auf GitHub öffnen" -ForegroundColor White
Write-Host "  2. README.md überprüfen" -ForegroundColor White
Write-Host "  3. Topics hinzufügen: nextcloud, docker, docker-compose, enterprise" -ForegroundColor White
Write-Host "  4. Bei Bedarf Collaborators einladen" -ForegroundColor White
Write-Host ""

Write-Info "Verwendung für andere:"
Write-Host "  git clone $($RepoUrl -replace '\.git$', '.git')" -ForegroundColor Gray
Write-Host "  cd $(Split-Path -Leaf $RepoUrl -replace '\.git$', '')" -ForegroundColor Gray
Write-Host "  cp .env.example .env" -ForegroundColor Gray
Write-Host "  # .env bearbeiten" -ForegroundColor Gray
Write-Host "  .\setup.ps1" -ForegroundColor Gray
Write-Host ""

# Repository im Browser öffnen
$openBrowser = Read-Host "Repository im Browser öffnen? (j/n)"
if ($openBrowser -eq "j" -or $openBrowser -eq "J") {
    $repoWebUrl = $RepoUrl -replace '\.git$', '' -replace 'git@github.com:', 'https://github.com/'
    Start-Process $repoWebUrl
}

Write-Host ""
Write-Host "Fertig! 🎉" -ForegroundColor Green
Write-Host ""
