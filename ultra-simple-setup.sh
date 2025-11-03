#!/bin/bash

# MacReplay Ultra-Simple Setup für Unraid
# Verwendet vereinfachtes Dockerfile ohne User-Management-Probleme

set -e

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}"
echo "=================================================="
echo "   MacReplay Ultra-Simple Setup"
echo "=================================================="
echo -e "${NC}"

# Überprüfe Dateien
log_info "Überprüfe Dateien..."
if [[ ! -f "app-docker.py" ]] || [[ ! -f "stb.py" ]] || [[ ! -f "requirements.txt" ]] || [[ ! -d "templates" ]] || [[ ! -d "static" ]]; then
    log_error "Nicht alle notwendigen Dateien gefunden!"
    exit 1
fi
log_info "✅ Alle Dateien vorhanden."

# Erstelle Verzeichnisse
log_info "Erstelle Datenverzeichnisse..."
mkdir -p /mnt/user/appdata/macreplay/data
mkdir -p /mnt/user/appdata/macreplay/logs
chown -R 99:65534 /mnt/user/appdata/macreplay/data /mnt/user/appdata/macreplay/logs 2>/dev/null || true

# Stoppe alte Container
log_info "Stoppe alte Container..."
docker stop macreplay 2>/dev/null || true
docker rm macreplay 2>/dev/null || true
docker rmi macreplay:simple 2>/dev/null || true

# Baue mit einfachem Dockerfile
log_info "Baue Image mit vereinfachtem Dockerfile..."
docker build -t macreplay:simple -f Dockerfile-simple .

# Starte Container
log_info "Starte Container..."
docker run -d \
    --name macreplay \
    --hostname macreplay \
    --restart unless-stopped \
    -p 8001:8001 \
    -v /mnt/user/appdata/macreplay/data:/app/data \
    -v /mnt/user/appdata/macreplay/logs:/app/logs \
    -e TZ=Europe/Berlin \
    -e PYTHONUNBUFFERED=1 \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    macreplay:simple

# Status prüfen
sleep 5
if docker ps | grep -q "macreplay"; then
    log_info "✅ MacReplay läuft!"
    local_ip=$(hostname -I | awk '{print $1}')
    echo
    log_info "🌐 Web-UI: http://${local_ip}:8001"
    echo
    echo "Befehle:"
    echo "  Logs:    docker logs macreplay -f"
    echo "  Stop:    docker stop macreplay"
    echo "  Start:   docker start macreplay"
else
    log_error "❌ Container-Start fehlgeschlagen!"
    docker logs macreplay
fi