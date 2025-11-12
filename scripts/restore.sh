#!/bin/bash
#
# Nextcloud Restore Script
# Stellt Backups wieder her
#

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

BACKUP_DIR="/backups"

# Zeige verfügbare Backups
log "=== Verfügbare Datenbank-Backups ==="
ls -lh "$BACKUP_DIR/database/" 2>/dev/null || echo "Keine Backups gefunden"

echo ""
read -p "Geben Sie den Namen des Backup-Files ein (z.B. nextcloud_db_20240101_120000.sql.gz): " BACKUP_FILE

if [ ! -f "$BACKUP_DIR/database/$BACKUP_FILE" ]; then
    error "Backup-Datei nicht gefunden: $BACKUP_FILE"
    exit 1
fi

warning "ACHTUNG: Dies wird die aktuelle Datenbank überschreiben!"
read -p "Sind Sie sicher? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log "Wiederherstellung abgebrochen."
    exit 0
fi

log "Stelle Datenbank wieder her..."
gunzip -c "$BACKUP_DIR/database/$BACKUP_FILE" | psql -h db -U "$POSTGRES_USER" "$POSTGRES_DB"

log "✓ Datenbank erfolgreich wiederhergestellt!"
log "Bitte starten Sie die Nextcloud-Container neu: docker-compose restart nextcloud"

exit 0
