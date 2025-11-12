# GitHub Upload - Einfache Anleitung

## ✅ Schritt 1: GitHub Repository erstellen

1. Öffnen Sie in Ihrem Browser: **https://github.com/new**

2. Füllen Sie das Formular aus:
   - **Repository name:** `nextcloud-production-enterprise`
   - **Description:** `Enterprise Nextcloud Setup für 500+ Benutzer mit Docker`
   - **Visibility:** ⚠️ **Private** (empfohlen - enthält Konfigurationen!)
   - **Initialize this repository:**
     - ❌ **NICHT** ankreuzen "Add a README file"
     - ❌ **NICHT** ankreuzen "Add .gitignore"
     - ❌ **NICHT** ankreuzen "Choose a license"

3. Klicken Sie: **Create repository**

4. **Kopieren Sie die Repository URL** (wird angezeigt nach der Erstellung)
   - Format: `https://github.com/IhrUsername/nextcloud-production-enterprise.git`

---

## ✅ Schritt 2: Git-Befehle ausführen

Öffnen Sie PowerShell im `production` Ordner und führen Sie folgende Befehle aus:

### 2.1 Git initialisieren
```powershell
git init
```

### 2.2 Alle Dateien hinzufügen
```powershell
git add .
```

### 2.3 Ersten Commit erstellen
```powershell
git commit -m "Initial commit: Nextcloud Production Setup for 500+ users"
```

### 2.4 Branch umbenennen
```powershell
git branch -M main
```

### 2.5 Remote Repository verbinden
**⚠️ WICHTIG: Ersetzen Sie die URL mit Ihrer eigenen!**
```powershell
git remote add origin https://github.com/IhrUsername/nextcloud-production-enterprise.git
```

### 2.6 Zu GitHub hochladen
```powershell
git push -u origin main
```

**Hinweis:** Sie werden nach GitHub-Zugangsdaten gefragt.

---

## ✅ Schritt 3: Verifizieren

1. Öffnen Sie Ihr Repository auf GitHub
2. Prüfen Sie, ob alle Dateien hochgeladen wurden
3. Die `.env` Datei sollte **NICHT** sichtbar sein (steht in .gitignore)

---

## 📝 Wichtige Dateien

### ✅ Hochgeladen werden:
- `docker-compose.yml`
- `README.md`
- `.env.example` ← Template ohne echte Passwörter
- `.gitignore`
- `setup.ps1` / `setup.sh`
- `config/` Ordner
- `scripts/` Ordner
- `monitoring/` Ordner

### ❌ NICHT hochgeladen (steht in .gitignore):
- `.env` ← Enthält Ihre echten Passwörter!
- `backups/` ← Ihre Backup-Dateien
- `ssl/` ← SSL-Zertifikate
- Logs und temporäre Dateien

---

## 🔐 Sicherheitshinweis

⚠️ **NIEMALS** die `.env` Datei mit echten Passwörtern hochladen!
⚠️ Verwenden Sie ein **Private Repository** für Production-Setups!

---

## 🆘 Hilfe bei Problemen

### Git ist nicht installiert?
```powershell
# Windows: Download von
https://git-scm.com/download/win
```

### GitHub-Authentifizierung?
- **Option 1:** GitHub Desktop verwenden
- **Option 2:** Personal Access Token erstellen (https://github.com/settings/tokens)
- **Option 3:** SSH-Key einrichten

### Fehler beim Push?
```powershell
# Remote prüfen
git remote -v

# Nochmal versuchen
git push -u origin main --force
```

---

## ✅ Nach dem Upload

1. **README anpassen** auf GitHub (optional)
2. **Topics hinzufügen:** nextcloud, docker, docker-compose, enterprise
3. **License hinzufügen** (optional): Settings → Add License
4. **Collaborators einladen** (falls Team-Projekt)

---

## 🎯 Verwendung nach dem Upload

Andere können das Repository klonen mit:
```bash
git clone https://github.com/IhrUsername/nextcloud-production-enterprise.git
cd nextcloud-production-enterprise
cp .env.example .env
# .env bearbeiten mit eigenen Werten
./setup.ps1  # oder ./setup.sh auf Linux
```

---

**Fertig! 🎉**
