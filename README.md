# 🏢 Nextcloud Production Environment
## Enterprise-Ready Setup für 500+ Benutzer

Diese Production-Umgebung bietet eine vollständig konfigurierte, sichere und skalierbare Nextcloud-Installation mit allen Enterprise-Features.

---

## 📋 Inhaltsverzeichnis

1. [Features](#features)
2. [Voraussetzungen](#voraussetzungen)
3. [Schnellstart](#schnellstart)
4. [Detaillierte Installation](#detaillierte-installation)
5. [SSL-Zertifikate](#ssl-zertifikate)
6. [Konfiguration](#konfiguration)
7. [Backup & Restore](#backup--restore)
8. [Monitoring](#monitoring)
9. [Wartung & Updates](#wartung--updates)
10. [Performance-Tuning](#performance-tuning)
11. [Troubleshooting](#troubleshooting)
12. [Sicherheit](#sicherheit)

---

## 🚀 Features

### Basis-Services
- ✅ **Nextcloud** (stable-fpm) - Optimiert für 500+ Benutzer
- ✅ **PostgreSQL 15** - Performance-optimierte Datenbank
- ✅ **Redis** - Caching für maximale Performance
- ✅ **Nginx** - Reverse Proxy mit HTTP/2 & SSL
- ✅ **Let's Encrypt** - Automatische SSL-Zertifikate

### Enterprise Features
- ✅ **Nextcloud Talk** - Video/Audio-Konferenzen (Teams-Alternative)
- ✅ **OnlyOffice** - Vollständige Office-Suite (Word, Excel, PowerPoint)
- ✅ **TURN/STUN Server** - WebRTC für Talk (coturn)
- ✅ **Automatische Backups** - Täglich, konfigurierbar
- ✅ **Health Monitoring** - System-Überwachung
- ✅ **Cron Jobs** - Background-Tasks

### Sicherheit & Performance
- ✅ **HTTPS** mit modernen Ciphers
- ✅ **Security Headers** (HSTS, CSP, etc.)
- ✅ **Rate Limiting** (DDoS-Schutz)
- ✅ **Optimierte PHP & PostgreSQL** Konfiguration
- ✅ **Redis Caching** für schnelle Antwortzeiten
- ✅ **Health Checks** für alle Container

---

## 📦 Voraussetzungen

### Hardware (Empfohlen für 500 Benutzer)
- **CPU:** 16 Kerne (min. 8 Kerne)
- **RAM:** 64 GB (min. 32 GB)
- **Storage:** 2-4 TB SSD mit RAID
- **Netzwerk:** 1 Gbit/s
- **USV:** Unterbrechungsfreie Stromversorgung empfohlen

### Software
- **Betriebssystem:** Ubuntu Server 22.04 LTS, Debian 12, oder Windows Server
- **Docker:** Version 24.0+
- **Docker Compose:** Version 2.20+
- **Domain:** Registrierte Domain mit DNS-Zugriff
- **Ports:** 80, 443, 3478 (UDP/TCP), 49160-49200 (UDP)

### Netzwerk-Anforderungen
- **Öffentliche IP-Adresse** oder DynDNS
- **Port-Forwarding** im Router eingerichtet
- **DNS A-Record** zeigt auf Ihre Server-IP

---

## ⚡ Schnellstart

### 1. Repository klonen oder Dateien kopieren
```bash
cd production/
```

### 2. Umgebungsvariablen konfigurieren
```bash
# Bearbeiten Sie die .env Datei
nano .env
```

**WICHTIG:** Ändern Sie ALLE Passwörter und tragen Sie Ihre Domain ein!

### 3. SSL-Zertifikate vorbereiten
```bash
# Für Let's Encrypt: Setup-Skript ausführen
./scripts/setup-ssl.sh
```

### 4. Container starten
```bash
docker-compose up -d
```

### 5. Status überprüfen
```bash
docker-compose ps
./scripts/health-check.sh
```

### 6. Nextcloud aufrufen
Öffnen Sie: `https://ihre-domain.de`

---

## 🔧 Detaillierte Installation

### Schritt 1: Server vorbereiten

#### Linux (Ubuntu/Debian)
```bash
# System aktualisieren
sudo apt update && sudo apt upgrade -y

# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Compose installieren
sudo apt install docker-compose-plugin -y

# Benutzer zur Docker-Gruppe hinzufügen
sudo usermod -aG docker $USER

# Neu anmelden für Gruppenänderungen
newgrp docker
```

#### Windows Server
1. Docker Desktop für Windows installieren
2. PowerShell als Administrator öffnen
3. WSL2 aktivieren (falls nötig)

### Schritt 2: Projekt-Dateien vorbereiten

```bash
# In Projektverzeichnis wechseln
cd /pfad/zu/production/

# Berechtigungen für Skripte setzen (Linux)
chmod +x scripts/*.sh
```

### Schritt 3: Konfiguration anpassen

#### .env Datei bearbeiten
```bash
nano .env
```

**Mindestens ändern:**
- `NEXTCLOUD_DOMAIN` - Ihre echte Domain
- `LETSENCRYPT_EMAIL` - Ihre E-Mail-Adresse
- `POSTGRES_PASSWORD` - Sicheres Datenbank-Passwort
- `REDIS_PASSWORD` - Sicheres Redis-Passwort
- `NEXTCLOUD_ADMIN_PASSWORD` - Sicheres Admin-Passwort
- `ONLYOFFICE_JWT_SECRET` - Zufälliger String (min. 32 Zeichen)
- `TURN_SECRET` - Zufälliger String (min. 32 Zeichen)

**Passwörter generieren:**
```bash
# Sichere Passwörter generieren (Linux)
openssl rand -base64 32

# Windows PowerShell
[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

### Schritt 4: DNS konfigurieren

Erstellen Sie folgende DNS-Einträge:

| Typ | Name | Wert | TTL |
|-----|------|------|-----|
| A | cloud.ihre-firma.de | Ihre-Server-IP | 3600 |
| A | office.ihre-firma.de | Ihre-Server-IP | 3600 |

**Prüfen:**
```bash
nslookup cloud.ihre-firma.de
```

### Schritt 5: Firewall & Port-Forwarding

#### Router-Konfiguration
Leiten Sie folgende Ports weiter:
- `80` (HTTP) → Server-IP:80
- `443` (HTTPS) → Server-IP:443
- `3478` (UDP/TCP) → Server-IP:3478
- `49160-49200` (UDP) → Server-IP:49160-49200

#### Linux Firewall (UFW)
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 49160:49200/udp
sudo ufw enable
```

#### Windows Firewall
```powershell
New-NetFirewallRule -DisplayName "Nextcloud HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Nextcloud HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "Nextcloud TURN TCP" -Direction Inbound -Protocol TCP -LocalPort 3478 -Action Allow
New-NetFirewallRule -DisplayName "Nextcloud TURN UDP" -Direction Inbound -Protocol UDP -LocalPort 3478 -Action Allow
```

---

## 🔐 SSL-Zertifikate

### Option A: Let's Encrypt (Automatisch, kostenlos)

#### Erstmalige Einrichtung
```bash
# SSL-Setup-Skript ausführen
./scripts/setup-ssl.sh

# ODER manuell:
# 1. Nginx Konfiguration für HTTP-only vorbereiten
docker-compose up -d nginx

# 2. Zertifikat beantragen
docker-compose run --rm certbot certonly --webroot \
  -w /var/www/certbot \
  -d ihre-domain.de \
  -d office.ihre-domain.de \
  --email ihre-email@domain.de \
  --agree-tos \
  --no-eff-email

# 3. Nginx Konfiguration auf HTTPS umstellen
# Bearbeiten Sie config/nginx/nextcloud.conf
# Ersetzen Sie "DOMAIN" mit Ihrer echten Domain

# 4. Alle Container neu starten
docker-compose down
docker-compose up -d
```

#### Automatische Erneuerung
Let's Encrypt-Zertifikate werden automatisch durch den Certbot-Container erneuert.

**Manuelle Erneuerung testen:**
```bash
docker-compose run --rm certbot renew --dry-run
```

### Option B: Eigenes SSL-Zertifikat

```bash
# Zertifikat-Dateien kopieren
mkdir -p ./ssl
cp ihr-zertifikat.crt ./ssl/fullchain.pem
cp ihr-privat-key.key ./ssl/privkey.pem

# Nginx-Konfiguration anpassen
# In config/nginx/nextcloud.conf:
# ssl_certificate /etc/nginx/ssl/fullchain.pem;
# ssl_certificate_key /etc/nginx/ssl/privkey.pem;

# Volume in docker-compose.yml hinzufügen:
# - ./ssl:/etc/nginx/ssl:ro
```

---

## ⚙️ Konfiguration

### Nextcloud Talk konfigurieren

1. Als Admin anmelden
2. **Einstellungen** → **Verwaltung** → **Talk**
3. TURN-Server eintragen:
   ```
   TURN-Server: turn:ihre-domain.de:3478
   Geheimer Schlüssel: [TURN_SECRET aus .env]
   Protokolle: UDP und TCP
   ```

### OnlyOffice konfigurieren

1. Talk-App installieren (falls nicht automatisch):
   ```bash
   docker exec -u www-data nextcloud_prod_app php occ app:install spreed
   docker exec -u www-data nextcloud_prod_app php occ app:enable spreed
   ```

2. OnlyOffice-App installieren:
   ```bash
   docker exec -u www-data nextcloud_prod_app php occ app:install onlyoffice
   docker exec -u www-data nextcloud_prod_app php occ app:enable onlyoffice
   ```

3. OnlyOffice-Server konfigurieren:
   - **Einstellungen** → **Verwaltung** → **ONLYOFFICE**
   - **Document Editing Service address:** `https://office.ihre-domain.de/`
   - **JWT-Secret:** [ONLYOFFICE_JWT_SECRET aus .env]

### Performance-Optimierung

#### Redis Caching aktivieren
```bash
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  redis host --value="redis"
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  redis port --value=6379
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  redis password --value="IHR_REDIS_PASSWORD"
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  memcache.local --value="\\OC\\Memcache\\APCu"
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  memcache.distributed --value="\\OC\\Memcache\\Redis"
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  memcache.locking --value="\\OC\\Memcache\\Redis"
```

#### Datei-Vorschau optimieren
```bash
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  preview_max_x --value=2048
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  preview_max_y --value=2048
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  jpeg_quality --value=60
```

---

## 💾 Backup & Restore

### Automatische Backups

Backups laufen automatisch täglich um 2 Uhr nachts.

**Konfiguration anpassen:**
```bash
# .env Datei bearbeiten
BACKUP_RETENTION_DAYS=30  # Aufbewahrungsdauer in Tagen
```

**Backup-Container starten:**
```bash
docker-compose --profile backup up -d backup
```

### Manuelles Backup

```bash
# Backup-Skript ausführen
docker-compose exec backup /backup.sh

# ODER von außen
./scripts/backup.sh
```

**Backup-Speicherort:** `./backups/`

### Backup wiederherstellen

```bash
# Restore-Skript ausführen
docker exec -it nextcloud_prod_backup /bin/bash
/restore.sh

# Liste verfügbarer Backups anzeigen
ls -lh /backups/database/
```

### Offsite-Backup (Empfohlen)

```bash
# Backups auf externen Server kopieren (rsync)
rsync -avz --delete ./backups/ backup-server:/pfad/zu/backups/

# ODER: Cloud-Upload (rclone)
rclone sync ./backups/ remote:nextcloud-backups/
```

---

## 📊 Monitoring

### Health-Check ausführen

```bash
# Alle Services prüfen
./scripts/health-check.sh
```

### Erweiteres Monitoring (Optional)

#### Prometheus & Grafana aktivieren
```bash
# Monitoring-Stack starten
docker-compose -f monitoring/docker-compose.monitoring.yml up -d

# Zugriff:
# Prometheus: http://server-ip:9090
# Grafana: http://server-ip:3000 (admin/admin)
```

### Logs anzeigen

```bash
# Alle Container
docker-compose logs -f

# Spezifischer Container
docker-compose logs -f nextcloud
docker-compose logs -f nginx
docker-compose logs -f db

# Letzte 100 Zeilen
docker-compose logs --tail=100 nextcloud
```

### System-Ressourcen überwachen

```bash
# Container-Ressourcen
docker stats

# Disk Usage
docker system df
df -h

# Nextcloud-spezifisch
docker exec nextcloud_prod_app du -sh /var/www/html/data
```

---

## 🔄 Wartung & Updates

### Nextcloud aktualisieren

```bash
# 1. Backup erstellen
./scripts/backup.sh

# 2. Container stoppen
docker-compose down

# 3. Images aktualisieren
docker-compose pull

# 4. Container neu starten
docker-compose up -d

# 5. Nextcloud-Upgrade durchführen
docker exec -u www-data nextcloud_prod_app php occ upgrade

# 6. Status prüfen
docker exec -u www-data nextcloud_prod_app php occ status
```

### Datenbank-Wartung

```bash
# Datenbank-Indizes optimieren
docker exec -u www-data nextcloud_prod_app php occ db:add-missing-indices

# Datei-Scans
docker exec -u www-data nextcloud_prod_app php occ files:scan --all

# Datenbank-Konvertierung (nach Upgrade)
docker exec -u www-data nextcloud_prod_app php occ db:convert-filecache-bigint
```

### System-Maintenance

```bash
# Maintenance-Mode aktivieren
docker exec -u www-data nextcloud_prod_app php occ maintenance:mode --on

# Ihre Wartungsarbeiten durchführen...

# Maintenance-Mode deaktivieren
docker exec -u www-data nextcloud_prod_app php occ maintenance:mode --off
```

---

## ⚡ Performance-Tuning

### Für 500+ Benutzer optimiert

Die Konfiguration ist bereits für 500 Benutzer optimiert. Bei mehr Benutzern:

#### PostgreSQL anpassen
Bearbeiten Sie `docker-compose.yml`:
```yaml
command:
  - -c
  - max_connections=1000  # von 500 erhöhen
  - -c
  - shared_buffers=4GB    # von 2GB erhöhen
```

#### PHP-Limits erhöhen
Bearbeiten Sie `config/php/php.ini`:
```ini
memory_limit = 4G          ; von 2G erhöhen
max_execution_time = 7200  ; von 3600 erhöhen
```

#### Redis-Cache vergrößern
Bearbeiten Sie `docker-compose.yml`:
```yaml
redis:
  command: >
    --maxmemory 8gb  # von 4gb erhöhen
```

### Caching optimieren

```bash
# APCu-Status prüfen
docker exec nextcloud_prod_app php -i | grep apc

# OPcache-Status
docker exec nextcloud_prod_app php -i | grep opcache
```

---

## 🐛 Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
docker-compose logs

# Container-Status
docker ps -a

# Speicherplatz prüfen
df -h

# Container neu erstellen
docker-compose down
docker-compose up -d --force-recreate
```

### Nextcloud ist nicht erreichbar

1. **Ports prüfen:**
   ```bash
   # Linux
   sudo netstat -tlnp | grep -E '80|443'
   
   # Windows
   netstat -an | findstr ":80 :443"
   ```

2. **Nginx-Konfiguration testen:**
   ```bash
   docker exec nextcloud_prod_nginx nginx -t
   ```

3. **SSL-Zertifikate prüfen:**
   ```bash
   ls -l /etc/letsencrypt/live/ihre-domain.de/
   openssl x509 -in fullchain.pem -text -noout
   ```

### Datenbank-Probleme

```bash
# Datenbank-Verbindung testen
docker exec nextcloud_prod_db pg_isready -U nextcloud_admin

# Datenbank-Größe
docker exec nextcloud_prod_db psql -U nextcloud_admin -d nextcloud_production -c "SELECT pg_size_pretty(pg_database_size('nextcloud_production'));"

# Datenbank-Backup manuell
docker exec nextcloud_prod_db pg_dump -U nextcloud_admin nextcloud_production > backup.sql
```

### Performance-Probleme

```bash
# Ressourcen-Nutzung
docker stats

# Slow Queries (PostgreSQL)
docker exec nextcloud_prod_db psql -U nextcloud_admin -d nextcloud_production -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Nextcloud-Logs auf Fehler prüfen
docker exec nextcloud_prod_app tail -f /var/www/html/data/nextcloud.log
```

### OnlyOffice funktioniert nicht

```bash
# OnlyOffice-Container Status
docker logs nextcloud_prod_onlyoffice

# JWT-Secret prüfen
docker exec -u www-data nextcloud_prod_app php occ config:app:get onlyoffice jwt_secret

# OnlyOffice neu starten
docker-compose restart onlyoffice
```

### Talk Video/Audio funktioniert nicht

1. **TURN-Server prüfen:**
   ```bash
   docker logs nextcloud_prod_coturn
   ```

2. **Ports offen?**
   ```bash
   # Port 3478 (TCP/UDP)
   nc -zv ihre-domain.de 3478
   
   # UDP-Ports 49160-49200
   ```

3. **TURN-Config in Nextcloud:**
   - Einstellungen → Talk → TURN-Server
   - `turn:ihre-domain.de:3478`
   - Secret aus `.env` eintragen

---

## 🔒 Sicherheit

### Empfohlene Sicherheitsmaßnahmen

#### 1. Zwei-Faktor-Authentifizierung aktivieren
```bash
# TOTP-App installieren
docker exec -u www-data nextcloud_prod_app php occ app:install twofactor_totp
docker exec -u www-data nextcloud_prod_app php occ app:enable twofactor_totp

# In Nextcloud: Einstellungen → Sicherheit → 2FA aktivieren
```

#### 2. Fail2ban installieren (Linux)
```bash
# Fail2ban installieren
sudo apt install fail2ban

# Nextcloud-Filter erstellen
sudo nano /etc/fail2ban/filter.d/nextcloud.conf
```

```ini
[Definition]
failregex = ^.*Login failed: '.*' \(Remote IP: '<HOST>'\).*$
            ^.*Bruteforce attempt from '<HOST>'.*$
ignoreregex =
```

```bash
# Jail konfigurieren
sudo nano /etc/fail2ban/jail.local
```

```ini
[nextcloud]
enabled = true
port = http,https
filter = nextcloud
logpath = /var/log/nextcloud/nextcloud.log
maxretry = 3
bantime = 3600
```

#### 3. Brute-Force Protection
```bash
docker exec -u www-data nextcloud_prod_app php occ config:app:set \
  bruteforcesettings attempts --value="3"
docker exec -u www-data nextcloud_prod_app php occ config:app:set \
  bruteforcesettings delay --value="30"
```

#### 4. Regelmäßige Security-Audits
```bash
# Nextcloud Security-Scan
docker exec -u www-data nextcloud_prod_app php occ security:scan

# Integrität prüfen
docker exec -u www-data nextcloud_prod_app php occ integrity:check-core
```

#### 5. HTTPS erzwingen
```bash
docker exec -u www-data nextcloud_prod_app php occ config:system:set \
  overwriteprotocol --value="https"
```

### Passwort-Richtlinien

```bash
# Minimale Passwort-Länge
docker exec -u www-data nextcloud_prod_app php occ config:app:set \
  password_policy minLength --value="12"

# Komplexität erzwingen
docker exec -u www-data nextcloud_prod_app php occ config:app:set \
  password_policy enforceNumericCharacters --value="1"
docker exec -u www-data nextcloud_prod_app php occ config:app:set \
  password_policy enforceSpecialCharacters --value="1"
```

### Sicherheits-Updates

```bash
# Regelmäßig Updates installieren
docker-compose pull
docker-compose up -d

# Ubuntu/Debian System-Updates
sudo apt update && sudo apt upgrade -y
```

---

## 📝 Zusätzliche Informationen

### Benutzer-Verwaltung

```bash
# Benutzer anlegen
docker exec -u www-data nextcloud_prod_app php occ user:add \
  --display-name="Max Mustermann" \
  --group="users" \
  mmax

# Benutzer löschen
docker exec -u www-data nextcloud_prod_app php occ user:delete mmax

# Alle Benutzer auflisten
docker exec -u www-data nextcloud_prod_app php occ user:list

# Passwort zurücksetzen
docker exec -u www-data nextcloud_prod_app php occ user:resetpassword mmax
```

### Gruppen-Verwaltung

```bash
# Gruppe erstellen
docker exec -u www-data nextcloud_prod_app php occ group:add "Abteilung-IT"

# Benutzer zu Gruppe hinzufügen
docker exec -u www-data nextcloud_prod_app php occ group:adduser "Abteilung-IT" mmax

# Gruppen auflisten
docker exec -u www-data nextcloud_prod_app php occ group:list
```

### Speicher-Quotas

```bash
# Standard-Quota setzen (in MB)
docker exec -u www-data nextcloud_prod_app php occ config:app:set \
  files default_quota --value="50GB"

# Quota für einzelnen Benutzer
docker exec -u www-data nextcloud_prod_app php occ user:setting mmax files quota "100GB"
```

---

## 🆘 Support & Hilfe

### Offizielle Ressourcen
- **Nextcloud Dokumentation:** https://docs.nextcloud.com/
- **Nextcloud Forum:** https://help.nextcloud.com/
- **Nextcloud GitHub:** https://github.com/nextcloud/server

### Log-Dateien

```bash
# Nextcloud-Logs
docker exec nextcloud_prod_app cat /var/www/html/data/nextcloud.log

# Nginx-Logs
docker exec nextcloud_prod_nginx cat /var/log/nginx/error.log
docker exec nextcloud_prod_nginx cat /var/log/nginx/nextcloud_error.log

# PostgreSQL-Logs
docker-compose logs db

# Redis-Logs
docker-compose logs redis
```

### System-Informationen sammeln

```bash
# Für Support-Anfragen
docker-compose ps > system-info.txt
docker stats --no-stream >> system-info.txt
docker-compose logs --tail=100 >> system-info.txt
```

---

## 📄 Lizenz

Diese Konfiguration verwendet folgende Open-Source Software:
- **Nextcloud:** AGPLv3
- **PostgreSQL:** PostgreSQL License
- **Redis:** BSD License
- **Nginx:** BSD License
- **OnlyOffice:** AGPLv3
- **Coturn:** BSD License

---

## ✅ Checkliste: Production-Deployment

- [ ] Hardware-Anforderungen erfüllt
- [ ] Docker & Docker Compose installiert
- [ ] Domain registriert und DNS konfiguriert
- [ ] Alle Passwörter in `.env` geändert
- [ ] Ports im Router weitergeleitet
- [ ] Firewall konfiguriert
- [ ] SSL-Zertifikate eingerichtet
- [ ] Container gestartet und getestet
- [ ] Nextcloud Talk konfiguriert
- [ ] OnlyOffice konfiguriert
- [ ] Backup-System aktiviert
- [ ] Monitoring eingerichtet
- [ ] 2FA für Admin aktiviert
- [ ] Benutzer-Dokumentation erstellt
- [ ] Notfall-Kontakte definiert

---

**🎉 Herzlichen Glückwunsch! Ihre Enterprise Nextcloud-Installation ist bereit für 500+ Benutzer!**

Bei Fragen oder Problemen: Überprüfen Sie die Troubleshooting-Sektion oder kontaktieren Sie den Nextcloud-Support.
