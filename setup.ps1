# Nextcloud Production Setup Script
# Automatisierte Installation und Konfiguration
# Für Windows PowerShell

param(
    [switch]$SkipSSL = $false,
    [switch]$SkipValidation = $false
)

$ErrorActionPreference = "Stop"

# Farben für Output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput Green "✓ $Message"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-ColorOutput Red "✗ $Message"
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-ColorOutput Yellow "⚠ $Message"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput Cyan "ℹ $Message"
}

Write-Host ""
Write-ColorOutput Cyan "================================================"
Write-ColorOutput Cyan "   Nextcloud Production Setup"
Write-ColorOutput Cyan "   Enterprise-Ready für 500+ Benutzer"
Write-ColorOutput Cyan "================================================"
Write-Host ""

# Schritt 1: Voraussetzungen prüfen
Write-Info "[1/8] Prüfe Voraussetzungen..."

# Docker prüfen
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker installiert: $dockerVersion"
    } else {
        throw "Docker nicht gefunden"
    }
} catch {
    Write-Error-Custom "Docker ist nicht installiert oder läuft nicht!"
    Write-Host "Bitte installieren Sie Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
}

# Docker Compose prüfen
try {
    $composeVersion = docker-compose --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker Compose installiert: $composeVersion"
    } else {
        throw "Docker Compose nicht gefunden"
    }
} catch {
    Write-Error-Custom "Docker Compose ist nicht installiert!"
    exit 1
}

Write-Host ""

# Schritt 2: Konfiguration validieren
Write-Info "[2/8] Validiere Konfiguration..."

if (-not (Test-Path ".env")) {
    Write-Error-Custom ".env Datei nicht gefunden!"
    exit 1
}

# .env laden
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

# Kritische Variablen prüfen
$requiredVars = @(
    "NEXTCLOUD_DOMAIN",
    "POSTGRES_PASSWORD",
    "REDIS_PASSWORD",
    "NEXTCLOUD_ADMIN_PASSWORD",
    "ONLYOFFICE_JWT_SECRET"
)

$missingVars = @()
foreach ($var in $requiredVars) {
    if (-not (Get-Variable -Name $var -ErrorAction SilentlyContinue) -or 
        (Get-Variable -Name $var).Value -eq "" -or
        (Get-Variable -Name $var).Value -like "*AENDERN*") {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0 -and -not $SkipValidation) {
    Write-Error-Custom "Folgende Variablen müssen in .env konfiguriert werden:"
    foreach ($var in $missingVars) {
        Write-Host "  - $var"
    }
    Write-Host ""
    Write-Host "Bitte bearbeiten Sie die .env Datei und führen Sie das Skript erneut aus."
    exit 1
}

Write-Success "Konfiguration validiert"
Write-Host ""

# Schritt 3: Verzeichnisse erstellen
Write-Info "[3/8] Erstelle erforderliche Verzeichnisse..."

$directories = @(
    ".\backups\database",
    ".\backups\data",
    ".\backups\config",
    ".\config\nginx",
    ".\config\php",
    ".\config\coturn"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Erstellt: $dir"
    }
}

Write-Host ""

# Schritt 4: Nginx-Konfiguration vorbereiten
Write-Info "[4/8] Bereite Nginx-Konfiguration vor..."

if (Test-Path ".\config\nginx\nextcloud.conf") {
    $nginxConfig = Get-Content ".\config\nginx\nextcloud.conf" -Raw
    if ($nginxConfig -match "DOMAIN") {
        $nginxConfig = $nginxConfig -replace "DOMAIN", $NEXTCLOUD_DOMAIN
        Set-Content ".\config\nginx\nextcloud.conf" -Value $nginxConfig
        Write-Success "Nginx-Konfiguration aktualisiert mit Domain: $NEXTCLOUD_DOMAIN"
    } else {
        Write-Success "Nginx-Konfiguration bereits konfiguriert"
    }
}

Write-Host ""

# Schritt 5: TURN-Server Konfiguration
Write-Info "[5/8] Konfiguriere TURN-Server..."

if (Test-Path ".\config\coturn\turnserver.conf") {
    $turnConfig = Get-Content ".\config\coturn\turnserver.conf" -Raw
    $turnConfig = $turnConfig -replace "TURN_SECRET_PLACEHOLDER", $TURN_SECRET
    
    # Externe IP ermitteln (optional)
    try {
        $externalIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
        $turnConfig = $turnConfig -replace "EXTERNAL_IP_PLACEHOLDER", $externalIP
        Write-Success "Externe IP erkannt: $externalIP"
    } catch {
        Write-Warning-Custom "Externe IP konnte nicht ermittelt werden (wird später automatisch erkannt)"
        $turnConfig = $turnConfig -replace "external-ip=EXTERNAL_IP_PLACEHOLDER`r`n", ""
    }
    
    Set-Content ".\config\coturn\turnserver.conf" -Value $turnConfig
    Write-Success "TURN-Server konfiguriert"
}

Write-Host ""

# Schritt 6: SSL-Zertifikate
if (-not $SkipSSL) {
    Write-Info "[6/8] SSL-Zertifikate vorbereiten..."
    Write-Warning-Custom "SSL-Zertifikate müssen nach dem Start manuell konfiguriert werden."
    Write-Host "Siehe README.md → Abschnitt 'SSL-Zertifikate'"
    Write-Host ""
    
    Read-Host "Drücken Sie Enter um fortzufahren"
} else {
    Write-Info "[6/8] SSL-Setup übersprungen (--SkipSSL)"
}

Write-Host ""

# Schritt 7: Docker Container starten
Write-Info "[7/8] Starte Docker Container..."
Write-Host ""

try {
    docker-compose pull
    Write-Success "Docker Images heruntergeladen"
    
    docker-compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Container gestartet"
    } else {
        throw "Container-Start fehlgeschlagen"
    }
} catch {
    Write-Error-Custom "Fehler beim Starten der Container!"
    Write-Host "Prüfen Sie die Logs mit: docker-compose logs"
    exit 1
}

Write-Host ""

# Schritt 8: Warten auf Nextcloud
Write-Info "[8/8] Warte auf Nextcloud-Initialisierung..."
Write-Host "Dies kann einige Minuten dauern..."

$maxRetries = 60
$retryCount = 0
$isReady = $false

while ($retryCount -lt $maxRetries) {
    $retryCount++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost/status.php" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $isReady = $true
            break
        }
    } catch {
        # Ignorieren und weitermachen
    }
    
    if ($retryCount % 5 -eq 0) {
        Write-Host "  Warte... ($retryCount/$maxRetries)"
    }
    Start-Sleep -Seconds 2
}

Write-Host ""

if ($isReady) {
    Write-Success "Nextcloud ist bereit!"
} else {
    Write-Warning-Custom "Nextcloud antwortet noch nicht. Bitte warten Sie noch etwas."
}

Write-Host ""

# Zusammenfassung
Write-ColorOutput Green "================================================"
Write-ColorOutput Green "   Setup abgeschlossen!"
Write-ColorOutput Green "================================================"
Write-Host ""

Write-ColorOutput Cyan "📋 Nächste Schritte:"
Write-Host ""

Write-Host "1. " -NoNewline
Write-ColorOutput Yellow "SSL-Zertifikate einrichten (siehe README.md)"

Write-Host "2. Nextcloud aufrufen:"
Write-ColorOutput White "   http://localhost (vorerst HTTP)"
Write-ColorOutput White "   Nach SSL-Setup: https://$NEXTCLOUD_DOMAIN"

Write-Host ""
Write-Host "3. Anmelden mit:"
Write-ColorOutput White "   Benutzername: $NEXTCLOUD_ADMIN_USER"
Write-ColorOutput White "   Passwort: [Ihr Admin-Passwort aus .env]"

Write-Host ""
Write-Host "4. Apps installieren:"
Write-ColorOutput White "   - Nextcloud Talk (Chat/Video)"
Write-ColorOutput White "   - OnlyOffice (Office-Dokumente)"

Write-Host ""
Write-Host "5. Container-Status prüfen:"
Write-ColorOutput White "   docker-compose ps"

Write-Host ""
Write-Host "6. Health-Check ausführen:"
Write-ColorOutput White "   .\scripts\health-check.sh"

Write-Host ""
Write-ColorOutput Cyan "📚 Dokumentation:"
Write-Host "   Vollständige Anleitung: .\README.md"

Write-Host ""
Write-ColorOutput Green "Viel Erfolg mit Ihrer Nextcloud-Installation! 🎉"
Write-Host ""
