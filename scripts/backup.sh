#!/bin/bash
#
# Nextcloud Backup Script
# Erstellt automatische Backups von Datenbank und Dateien
# Optimiert für Production-Umgebung
#

set -e

# Konfiguration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Erstelle Backup-Verzeichnis falls nicht vorhanden
mkdir -p "$BACKUP_DIR/database"
mkdir -p "$BACKUP_DIR/data"
mkdir -p "$BACKUP_DIR/config"

log "=== Nextcloud Backup gestartet ==="

# 1. Datenbank Backup
log "Erstelle Datenbank-Backup..."
if pg_dump -h db -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$BACKUP_DIR/database/nextcloud_db_${TIMESTAMP}.sql.gz"; then
    log "✓ Datenbank-Backup erstellt: nextcloud_db_${TIMESTAMP}.sql.gz"
    DB_SIZE=$(du -h "$BACKUP_DIR/database/nextcloud_db_${TIMESTAMP}.sql.gz" | cut -f1)
    log "  Größe: $DB_SIZE"
else
    error "✗ Datenbank-Backup fehlgeschlagen!"
    exit 1
fi

# 2. Nextcloud Daten Backup (optional, kann sehr groß sein)
log "Erstelle Nextcloud-Daten Backup..."
if tar -czf "$BACKUP_DIR/data/nextcloud_data_${TIMESTAMP}.tar.gz" -C /nextcloud_data . 2>/dev/null; then
    log "✓ Daten-Backup erstellt: nextcloud_data_${TIMESTAMP}.tar.gz"
    DATA_SIZE=$(du -h "$BACKUP_DIR/data/nextcloud_data_${TIMESTAMP}.tar.gz" | cut -f1)
    log "  Größe: $DATA_SIZE"
else
    warning "Daten-Backup übersprungen (möglicherweise zu groß oder keine Daten)"
fi

# 3. Config Backup
log "Erstelle Config-Backup..."
if [ -d "/var/www/html/config" ]; then
    if tar -czf "$BACKUP_DIR/config/nextcloud_config_${TIMESTAMP}.tar.gz" -C /var/www/html config 2>/dev/null; then
        log "✓ Config-Backup erstellt: nextcloud_config_${TIMESTAMP}.tar.gz"
    else
        warning "Config-Backup fehlgeschlagen"
    fi
fi

# 4. Alte Backups löschen
log "Lösche Backups älter als $RETENTION_DAYS Tage..."
find "$BACKUP_DIR/database" -name "nextcloud_db_*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
find "$BACKUP_DIR/data" -name "nextcloud_data_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
find "$BACKUP_DIR/config" -name "nextcloud_config_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
log "✓ Alte Backups gelöscht"

# 5. Backup-Statistik
log "=== Backup-Statistik ==="
DB_COUNT=$(find "$BACKUP_DIR/database" -name "nextcloud_db_*.sql.gz" | wc -l)
DATA_COUNT=$(find "$BACKUP_DIR/data" -name "nextcloud_data_*.tar.gz" | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log "  Datenbank-Backups: $DB_COUNT"
log "  Daten-Backups: $DATA_COUNT"
log "  Gesamtgröße: $TOTAL_SIZE"

log "=== Backup abgeschlossen ==="

# Optional: Backup-Status in Datei schreiben
echo "Last successful backup: $(date)" > "$BACKUP_DIR/last_backup.txt"

exit 0
