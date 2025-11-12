# Nextcloud Production Environment
Enterprise-ready Nextcloud setup für 500+ Benutzer mit Docker Compose

## Features
- ✅ Nextcloud (optimiert für 500+ Benutzer)
- ✅ PostgreSQL 15 (Performance-optimiert)
- ✅ Redis Caching
- ✅ Nginx Reverse Proxy mit SSL
- ✅ Let's Encrypt SSL-Zertifikate
- ✅ Nextcloud Talk (Video/Audio/Chat)
- ✅ OnlyOffice Document Server
- ✅ TURN/STUN Server für WebRTC
- ✅ Automatische Backups
- ✅ Health Monitoring

## Schnellstart

1. `.env` Datei anpassen (Domain & Passwörter ändern)
2. Setup ausführen:
   ```bash
   # Windows
   .\setup.ps1
   
   # Linux
   ./setup.sh
   ```
3. Nextcloud aufrufen: `https://ihre-domain.de`

## Dokumentation
Vollständige Anleitung siehe [README.md](README.md)

## Anforderungen
- Docker & Docker Compose
- 16 CPU-Kerne, 64GB RAM (empfohlen für 500 Benutzer)
- 2-4 TB SSD Storage
- Registrierte Domain mit DNS-Zugriff

## Lizenz
Open Source - Siehe individuelle Komponenten-Lizenzen
