#!/bin/bash

# MacReplay Legacy Docker Build Script
# Für Unraid-Systeme ohne Docker Buildx

set -e

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo "MacReplay Legacy Docker Build"
echo "============================="

# Überprüfe Dockerfile
if [[ -f "Dockerfile-unraid" ]]; then
    DOCKERFILE="Dockerfile-unraid"
    log_info "Verwende Dockerfile-unraid"
elif [[ -f "Dockerfile" ]]; then
    DOCKERFILE="Dockerfile"
    log_info "Verwende Dockerfile"
else
    log_error "Kein Dockerfile gefunden!"
    exit 1
fi

# Stoppe und entferne vorhandenen Container
log_info "Stoppe vorhandenen Container..."
docker stop macreplay 2>/dev/null || true
docker rm macreplay 2>/dev/null || true

# Entferne altes Image
log_info "Entferne altes Image..."
docker rmi macreplay:unraid 2>/dev/null || true

# Baue neues Image
log_info "Baue MacReplay Image..."
if [[ "$DOCKERFILE" == "Dockerfile-unraid" ]]; then
    docker build -t macreplay:unraid -f Dockerfile-unraid --build-arg PUID=99 --build-arg PGID=100 .
else
    docker build -t macreplay:unraid -f Dockerfile .
fi

# Erstelle Datenverzeichnisse
log_info "Erstelle Datenverzeichnisse..."
mkdir -p /mnt/user/appdata/macreplay/data
mkdir -p /mnt/user/appdata/macreplay/logs
chown -R 99:100 /mnt/user/appdata/macreplay/data /mnt/user/appdata/macreplay/logs

# Starte Container
log_info "Starte Container..."
docker run -d \
    --name macreplay \
    --hostname macreplay \
    --restart unless-stopped \
    --network bridge \
    -p 8001:8001 \
    -v /mnt/user/appdata/macreplay/data:/app/data \
    -v /mnt/user/appdata/macreplay/logs:/app/logs \
    -e PUID=99 \
    -e PGID=100 \
    -e TZ=Europe/Berlin \
    -e PYTHONUNBUFFERED=1 \
    --security-opt no-new-privileges:true \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    macreplay:unraid

# Warte und überprüfe Status
log_info "Warte auf Container-Start..."
sleep 5

if docker ps | grep -q "macreplay"; then
    log_info "✅ MacReplay Container läuft erfolgreich!"
    
    # Zeige Container-Info
    echo
    echo "Container-Informationen:"
    docker ps --filter name=macreplay --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Zeige Web-UI URL
    local_ip=$(hostname -I | awk '{print $1}')
    echo
    log_info "🌐 Web-UI: http://${local_ip}:8001"
    
    echo
    echo "Nützliche Befehle:"
    echo "  Status:    docker ps --filter name=macreplay"
    echo "  Logs:      docker logs macreplay -f"
    echo "  Stoppen:   docker stop macreplay"
    echo "  Starten:   docker start macreplay"
    echo "  Entfernen: docker stop macreplay && docker rm macreplay"
    
else
    log_error "❌ Fehler beim Starten des Containers!"
    log_info "Container-Logs:"
    docker logs macreplay
    exit 1
fi