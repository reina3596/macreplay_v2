# MacReplay für Unraid

Diese Anleitung erklärt, wie Sie MacReplay als Docker-Container in Unraid installieren und konfigurieren.

## Voraussetzungen

- Unraid Server mit Docker-Unterstützung
- Community Applications Plugin (CA) installiert
- Mindestens 1GB freier RAM
- Port 8001 verfügbar

## Installation

### Methode 1: Docker Compose (Empfohlen)

1. **Dateien auf Unraid kopieren:**
   ```bash
   # Erstellen Sie das Verzeichnis auf Ihrem Unraid-Server
   mkdir -p /mnt/user/appdata/macreplay/source
   
   # Kopieren Sie alle MacReplay-Dateien von Ihrem lokalen System nach:
   # /mnt/user/appdata/macreplay/source/
   # 
   # Benötigte Dateien:
   # - docker-compose-unraid.yml
   # - Dockerfile-unraid
   # - app-docker.py
   # - stb.py
   # - requirements.txt
   # - templates/ (komplettes Verzeichnis)
   # - static/ (komplettes Verzeichnis)
   ```

2. **Docker Compose installieren (falls nicht vorhanden):**
   ```bash
   # Über Unraid Terminal oder SSH
   curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
   ```

3. **Container starten:**
   ```bash
   cd /mnt/user/appdata/macreplay/source
   docker-compose -f docker-compose-unraid.yml up -d
   ```

### Methode 2: Unraid Docker Templates

1. **Template erstellen:**
   - Gehen Sie zu Docker → Add Container
   - Verwenden Sie folgende Einstellungen:

   ```
   Repository: macreplay:latest
   Docker Hub URL: (leer lassen - lokales Image)
   WebUI: http://[IP]:[PORT:8001]
   Port: 8001 → 8001 (TCP)
   
   Volume Mappings:
   /app/data → /mnt/user/appdata/macreplay/data
   /app/logs → /mnt/user/appdata/macreplay/logs
   
   Environment Variables:
   PUID = 99
   PGID = 100
   TZ = Europe/Berlin
   PYTHONUNBUFFERED = 1
   ```

## Konfiguration

### Verzeichnisstruktur auf Unraid

```
/mnt/user/appdata/macreplay/
├── source/                 # MacReplay Quellcode (für Docker Build)
│   ├── docker-compose-unraid.yml
│   ├── Dockerfile
│   ├── app-docker.py
│   ├── stb.py
│   ├── requirements.txt
│   ├── templates/
│   └── static/
├── data/                   # Persistente Daten
│   └── MacReplay.json     # Konfigurationsdatei
└── logs/                   # Log-Dateien
    └── macreplay.log
```

### Erste Konfiguration

1. **Zugriff auf die Web-UI:**
   ```
   http://UNRAID-IP:8001
   ```

2. **Portal hinzufügen:**
   - Gehen Sie zu "Portals"
   - Klicken Sie "Add Portal"
   - Geben Sie Ihre IPTV-Portal-Details ein

3. **Channels konfigurieren:**
   - Gehen Sie zu "Channel Editor"
   - Aktivieren/deaktivieren Sie gewünschte Kanäle
   - Speichern Sie die Änderungen

## Unraid-spezifische Einstellungen

### Benutzer und Gruppierungen
```bash
PUID=99   # nobody user (Standard in Unraid)
PGID=100  # users group (Standard in Unraid)
```

### Ressourcenlimits
Die docker-compose-unraid.yml enthält folgende Limits:
- CPU: 2 Cores maximum, 0.5 Cores reserved
- RAM: 1GB maximum, 256MB reserved

Diese können je nach Server-Hardware angepasst werden.

### Netzwerk-Konfiguration
- **Bridge-Modus:** Standard für Unraid
- **Port 8001:** Web-Interface
- **Gesundheitscheck:** Überwacht Container-Status

## Wartung

### Container-Logs anzeigen
```bash
docker logs macreplay
```

### Container neustarten
```bash
cd /mnt/user/appdata/macreplay/source
docker-compose -f docker-compose-unraid.yml restart
```

### Container updaten
```bash
cd /mnt/user/appdata/macreplay/source
docker-compose -f docker-compose-unraid.yml down
# Neue Dateien von lokaler Entwicklung kopieren
# Dann rebuilden:
docker-compose -f docker-compose-unraid.yml build --no-cache
docker-compose -f docker-compose-unraid.yml up -d
```

### Backup erstellen
```bash
# Stoppen Sie den Container
docker-compose -f docker-compose-unraid.yml down

# Erstellen Sie ein Backup
tar -czf macreplay-backup-$(date +%Y%m%d).tar.gz -C /mnt/user/appdata macreplay/

# Starten Sie den Container wieder
docker-compose -f docker-compose-unraid.yml up -d
```

## Automatische Updates

### User Scripts Plugin verwenden

1. Installieren Sie das "User Scripts" Plugin
2. Erstellen Sie ein neues Script mit folgendem Inhalt:

```bash
#!/bin/bash
# MacReplay Manual Update Script (ohne Git)

COMPOSE_FILE="/mnt/user/appdata/macreplay/source/docker-compose-unraid.yml"
LOG_FILE="/mnt/user/appdata/macreplay/logs/update.log"

echo "$(date): Starting MacReplay manual update" >> $LOG_FILE

cd /mnt/user/appdata/macreplay/source

# HINWEIS: Vor dem Ausführen dieses Scripts müssen Sie
# die neuen Dateien manuell in das source-Verzeichnis kopieren

# Rebuild and restart
docker-compose -f docker-compose-unraid.yml down >> $LOG_FILE 2>&1
docker-compose -f docker-compose-unraid.yml build --no-cache >> $LOG_FILE 2>&1
docker-compose -f docker-compose-unraid.yml up -d >> $LOG_FILE 2>&1

echo "$(date): MacReplay update completed" >> $LOG_FILE
```

3. Stellen Sie es auf wöchentliche Ausführung ein

## Troubleshooting

### Container startet nicht
```bash
# Logs überprüfen
docker logs macreplay

# Ports überprüfen
netstat -tulpn | grep 8001

# Berechtigungen überprüfen
ls -la /mnt/user/appdata/macreplay/
```

### Web-Interface nicht erreichbar
1. Überprüfen Sie die Firewall-Einstellungen
2. Stellen Sie sicher, dass Port 8001 nicht von anderen Services verwendet wird
3. Prüfen Sie die Unraid-Netzwerk-Einstellungen

### Performance-Probleme
1. Erhöhen Sie die Ressourcenlimits in der docker-compose-unraid.yml
2. Überwachen Sie die Unraid-Systemlast
3. Überprüfen Sie die Festplatten-Performance

## Support

Bei Problemen:
1. Überprüfen Sie die Container-Logs
2. Überprüfen Sie die MacReplay-Logs in `/mnt/user/appdata/macreplay/logs/`
3. Stellen Sie sicher, dass alle Abhängigkeiten installiert sind

## Sicherheitshinweise

- Der Container läuft mit eingeschränkten Privilegien
- Logs werden automatisch rotiert
- Gesundheitschecks überwachen den Container-Status
- Netzwerk-Zugriff ist auf notwendige Ports beschränkt