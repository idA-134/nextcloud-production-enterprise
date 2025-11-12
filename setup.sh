#!/bin/bash
#
# Nextcloud Production Setup Script
# Automatisierte Installation und Konfiguration
# Für Linux (Ubuntu/Debian)
#

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

header() {
    echo -e "${CYAN}$1${NC}"
}

echo ""
header "================================================"
header "   Nextcloud Production Setup"
header "   Enterprise-Ready für 500+ Benutzer"
header "================================================"
echo ""

# Schritt 1: Voraussetzungen prüfen
info "[1/8] Prüfe Voraussetzungen..."

# Docker prüfen
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log "Docker installiert: $DOCKER_VERSION"
else
    error "Docker ist nicht installiert!"
    echo "Installation: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Docker Compose prüfen
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    log "Docker Compose installiert: $COMPOSE_VERSION"
else
    error "Docker Compose ist nicht installiert!"
    echo "Installation: sudo apt install docker-compose-plugin"
    exit 1
fi

echo ""

# Schritt 2: Konfiguration validieren
info "[2/8] Validiere Konfiguration..."

if [ ! -f ".env" ]; then
    error ".env Datei nicht gefunden!"
    exit 1
fi

# .env laden
source .env

# Kritische Variablen prüfen
REQUIRED_VARS=(
    "NEXTCLOUD_DOMAIN"
    "POSTGRES_PASSWORD"
    "REDIS_PASSWORD"
    "NEXTCLOUD_ADMIN_PASSWORD"
    "ONLYOFFICE_JWT_SECRET"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" == *"AENDERN"* ]]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    error "Folgende Variablen müssen in .env konfiguriert werden:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Bitte bearbeiten Sie die .env Datei und führen Sie das Skript erneut aus."
    exit 1
fi

log "Konfiguration validiert"
echo ""

# Schritt 3: Verzeichnisse erstellen
info "[3/8] Erstelle erforderliche Verzeichnisse..."

mkdir -p ./backups/{database,data,config}
mkdir -p ./config/{nginx,php,coturn}
mkdir -p ./ssl

log "Verzeichnisse erstellt"
echo ""

# Schritt 4: Nginx-Konfiguration vorbereiten
info "[4/8] Bereite Nginx-Konfiguration vor..."

if [ -f "./config/nginx/nextcloud.conf" ]; then
    sed -i "s/DOMAIN/$NEXTCLOUD_DOMAIN/g" ./config/nginx/nextcloud.conf
    log "Nginx-Konfiguration aktualisiert mit Domain: $NEXTCLOUD_DOMAIN"
fi

echo ""

# Schritt 5: TURN-Server Konfiguration
info "[5/8] Konfiguriere TURN-Server..."

if [ -f "./config/coturn/turnserver.conf" ]; then
    sed -i "s/TURN_SECRET_PLACEHOLDER/$TURN_SECRET/g" ./config/coturn/turnserver.conf
    
    # Externe IP ermitteln
    EXTERNAL_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ]; then
        sed -i "s/EXTERNAL_IP_PLACEHOLDER/$EXTERNAL_IP/g" ./config/coturn/turnserver.conf
        log "Externe IP erkannt: $EXTERNAL_IP"
    else
        warning "Externe IP konnte nicht ermittelt werden (wird später automatisch erkannt)"
        sed -i "/external-ip=EXTERNAL_IP_PLACEHOLDER/d" ./config/coturn/turnserver.conf
    fi
    
    log "TURN-Server konfiguriert"
fi

echo ""

# Schritt 6: SSL-Zertifikate
info "[6/8] SSL-Zertifikate vorbereiten..."
warning "SSL-Zertifikate müssen nach dem Start manuell konfiguriert werden."
echo "Siehe README.md → Abschnitt 'SSL-Zertifikate'"
echo ""

read -p "Drücken Sie Enter um fortzufahren..."

echo ""

# Schritt 7: Docker Container starten
info "[7/8] Starte Docker Container..."
echo ""

docker-compose pull
log "Docker Images heruntergeladen"

docker-compose up -d
log "Container gestartet"

echo ""

# Schritt 8: Warten auf Nextcloud
info "[8/8] Warte auf Nextcloud-Initialisierung..."
echo "Dies kann einige Minuten dauern..."

MAX_RETRIES=60
RETRY_COUNT=0
IS_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    ((RETRY_COUNT++))
    
    if curl -f -s -o /dev/null http://localhost/status.php 2>/dev/null; then
        IS_READY=true
        break
    fi
    
    if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
        echo "  Warte... ($RETRY_COUNT/$MAX_RETRIES)"
    fi
    sleep 2
done

echo ""

if [ "$IS_READY" = true ]; then
    log "Nextcloud ist bereit!"
else
    warning "Nextcloud antwortet noch nicht. Bitte warten Sie noch etwas."
fi

echo ""

# Zusammenfassung
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Setup abgeschlossen!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

echo -e "${CYAN}📋 Nächste Schritte:${NC}"
echo ""

echo -e "1. ${YELLOW}SSL-Zertifikate einrichten (siehe README.md)${NC}"
echo ""

echo "2. Nextcloud aufrufen:"
echo -e "   ${WHITE}http://localhost${NC} (vorerst HTTP)"
echo -e "   Nach SSL-Setup: ${WHITE}https://$NEXTCLOUD_DOMAIN${NC}"
echo ""

echo "3. Anmelden mit:"
echo -e "   Benutzername: ${WHITE}$NEXTCLOUD_ADMIN_USER${NC}"
echo -e "   Passwort: ${WHITE}[Ihr Admin-Passwort aus .env]${NC}"
echo ""

echo "4. Apps installieren:"
echo -e "   ${WHITE}- Nextcloud Talk (Chat/Video)${NC}"
echo -e "   ${WHITE}- OnlyOffice (Office-Dokumente)${NC}"
echo ""

echo "5. Container-Status prüfen:"
echo -e "   ${WHITE}docker-compose ps${NC}"
echo ""

echo "6. Health-Check ausführen:"
echo -e "   ${WHITE}./scripts/health-check.sh${NC}"
echo ""

echo -e "${CYAN}📚 Dokumentation:${NC}"
echo "   Vollständige Anleitung: ./README.md"
echo ""

echo -e "${GREEN}Viel Erfolg mit Ihrer Nextcloud-Installation! 🎉${NC}"
echo ""
