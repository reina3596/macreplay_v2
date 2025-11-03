# MacReplay - Lokale Installation für Unraid

## Übersicht

MacReplay ist eine lokale Anwendung ohne GitHub-Repository. Alle Dateien werden manuell von Ihrem Entwicklungssystem auf Unraid übertragen.

## Benötigte Dateien für Unraid-Installation

### Haupt-Dateien:
- `docker-compose-unraid.yml` - Docker Compose-Konfiguration für Unraid
- `Dockerfile-unraid` - Docker-Image-Definition für Unraid
- `app-docker.py` - Hauptanwendung (Flask-Server)
- `stb.py` - STB-Proxy-Funktionalität
- `requirements.txt` - Python-Abhängigkeiten

### Verzeichnisse:
- `templates/` - HTML-Templates (alle .html-Dateien)
- `static/` - Statische Dateien (CSS, JS, Bilder)

### Optionale Dateien:
- `README-Unraid.md` - Diese Anleitung
- `unraid-template.xml` - Unraid Docker-Template
- `setup-unraid.sh` - Automatisches Setup-Script

## Schritt-für-Schritt Installation

### 1. Dateien sammeln
Stellen Sie sicher, dass Sie alle oben genannten Dateien haben:
```
MacReplay/
├── docker-compose-unraid.yml
├── Dockerfile-unraid
├── app-docker.py
├── stb.py
├── requirements.txt
├── setup-unraid.sh
├── templates/
│   ├── base.html
│   ├── dashboard.html
│   ├── editor.html
│   ├── portals.html
│   └── settings.html
└── static/
    └── style.css
```

### 2. Dateien auf Unraid übertragen

**Option A: USB/Netzwerk-Übertragung**
```bash
# Kopieren Sie alle Dateien nach:
/mnt/user/appdata/macreplay/source/
```

**Option B: Direkt per SSH/Terminal**
```bash
# Auf Unraid Terminal:
mkdir -p /mnt/user/appdata/macreplay/source
cd /mnt/user/appdata/macreplay/source

# Dann per SCP, SFTP oder USB-Stick alle Dateien übertragen
```

### 3. Installation starten

**Automatisch (empfohlen):**
```bash
cd /mnt/user/appdata/macreplay/source
chmod +x setup-unraid.sh
./setup-unraid.sh
```

**Manuell:**
```bash
cd /mnt/user/appdata/macreplay/source
docker-compose -f docker-compose-unraid.yml up -d --build
```

## Update-Prozess

Da es sich um eine lokale Installation handelt, ist der Update-Prozess manuell:

### 1. Container stoppen
```bash
cd /mnt/user/appdata/macreplay/source
docker-compose -f docker-compose-unraid.yml down
```

### 2. Neue Dateien übertragen
Kopieren Sie die aktualisierten Dateien nach:
```
/mnt/user/appdata/macreplay/source/
```

### 3. Container neu bauen und starten
```bash
docker-compose -f docker-compose-unraid.yml up -d --build
```

**Oder mit Setup-Script:**
```bash
./setup-unraid.sh --update
```

## Datei-Struktur auf Unraid

```
/mnt/user/appdata/macreplay/
├── source/                    # Quellcode-Dateien
│   ├── docker-compose-unraid.yml
│   ├── Dockerfile-unraid
│   ├── app-docker.py
│   ├── stb.py
│   ├── requirements.txt
│   ├── templates/
│   └── static/
├── data/                      # Persistente Anwendungsdaten
│   └── MacReplay.json        # Konfigurationsdatei
└── logs/                      # Log-Dateien
    └── macreplay.log
```

## Backup und Wiederherstellung

### Backup erstellen:
```bash
cd /mnt/user/appdata
tar -czf macreplay-backup-$(date +%Y%m%d).tar.gz macreplay/
```

### Backup wiederherstellen:
```bash
cd /mnt/user/appdata
tar -xzf macreplay-backup-YYYYMMDD.tar.gz
```

## Versionskontrolle (optional)

Da es kein Git-Repository gibt, können Sie eigene Versionskontrolle implementieren:

### Versions-Backup:
```bash
# Vor jedem Update
cp -r /mnt/user/appdata/macreplay/source /mnt/user/appdata/macreplay/source-backup-$(date +%Y%m%d)
```

### Rollback:
```bash
# Container stoppen
docker-compose -f docker-compose-unraid.yml down

# Alte Version wiederherstellen
rm -rf /mnt/user/appdata/macreplay/source
mv /mnt/user/appdata/macreplay/source-backup-YYYYMMDD /mnt/user/appdata/macreplay/source

# Container neu starten
docker-compose -f docker-compose-unraid.yml up -d --build
```

## Entwicklung und Testing

### Lokale Änderungen testen:
1. Bearbeiten Sie Dateien auf Ihrem Entwicklungssystem
2. Testen Sie lokal mit der Standard docker-compose.yml
3. Übertragen Sie getestete Dateien auf Unraid
4. Rebuilden Sie den Container auf Unraid

### Template-Änderungen (mit Volume-Mounts):
Für schnelle Template-Änderungen können Sie temporär Volume-Mounts aktivieren:

```yaml
# In docker-compose-unraid.yml hinzufügen:
volumes:
  - /mnt/user/appdata/macreplay/source/templates:/app/templates
  - /mnt/user/appdata/macreplay/source/static:/app/static
```

## Troubleshooting

### Häufige Probleme:

1. **Dateien fehlen:**
   - Überprüfen Sie, dass alle Dateien korrekt übertragen wurden
   - Kontrollieren Sie Dateiberechtigungen (99:100)

2. **Container startet nicht:**
   ```bash
   docker logs macreplay
   ```

3. **Konfiguration zurücksetzen:**
   ```bash
   rm /mnt/user/appdata/macreplay/data/MacReplay.json
   docker-compose -f docker-compose-unraid.yml restart
   ```

## Support

Da dies eine lokale Installation ist:
- Überprüfen Sie Container-Logs: `docker logs macreplay`
- Überprüfen Sie Anwendungs-Logs: `/mnt/user/appdata/macreplay/logs/`
- Stellen Sie sicher, dass alle Dateien vollständig übertragen wurden