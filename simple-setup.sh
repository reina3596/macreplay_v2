#!/bin/bash

# MacReplay Unraid Setup - Legacy Docker (OHNE Buildx)
# Dieses Script umgeht alle Buildx-Probleme

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "=================================================="
echo "   MacReplay Unraid Setup (Legacy Docker)"
echo "=================================================="
echo -e "${NC}"

# Konfiguration
DATA_DIR="/mnt/user/appdata/macreplay/data"
LOGS_DIR="/mnt/user/appdata/macreplay/logs"

# Funktionen
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Überprüfe notwendige Dateien
log_info "Überprüfe notwendige Dateien..."

if [[ ! -f "app-docker.py" ]]; then
    log_error "app-docker.py fehlt!"
    exit 1
fi

if [[ ! -f "stb.py" ]]; then
    log_error "stb.py fehlt!"
    exit 1
fi

if [[ ! -f "requirements.txt" ]]; then
    log_error "requirements.txt fehlt!"
    exit 1
fi

if [[ ! -d "templates" ]]; then
    log_error "templates/ Verzeichnis fehlt!"
    exit 1
fi

if [[ ! -d "static" ]]; then
    log_error "static/ Verzeichnis fehlt!"
    exit 1
fi

log_info "✅ Alle notwendigen Dateien vorhanden."

# Erstelle Daten-Verzeichnisse
log_info "Erstelle Daten-Verzeichnisse..."
mkdir -p "$DATA_DIR"
mkdir -p "$LOGS_DIR"
chown -R 99:100 "$DATA_DIR" "$LOGS_DIR" 2>/dev/null || true
chmod -R 755 "$DATA_DIR" "$LOGS_DIR"

# Stoppe vorhandenen Container
log_info "Stoppe vorhandenen Container..."
docker stop macreplay 2>/dev/null || true
docker rm macreplay 2>/dev/null || true

# Entferne altes Image
log_info "Entferne altes Image..."
docker rmi macreplay:unraid 2>/dev/null || true

# Bestimme welches Dockerfile zu verwenden
DOCKERFILE=""
if [[ -f "Dockerfile-unraid" ]]; then
    DOCKERFILE="Dockerfile-unraid"
    log_info "Verwende Dockerfile-unraid"
elif [[ -f "Dockerfile" ]]; then
    DOCKERFILE="Dockerfile"
    log_info "Verwende Dockerfile"
else
    log_error "Kein Dockerfile gefunden! Erstelle einfaches Dockerfile..."
    
    # Erstelle ein einfaches Dockerfile falls keines existiert
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Create directories
RUN mkdir -p /app/data /app/logs

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app-docker.py app.py
COPY stb.py .
COPY templates/ templates/
COPY static/ static/

# Create user and set permissions
RUN useradd -m -u 99 macreplay && \
    chown -R 99:100 /app

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Switch to user and run application
USER macreplay
CMD ["python", "app.py"]
EOF

    DOCKERFILE="Dockerfile"
    log_info "Einfaches Dockerfile erstellt."
fi

# Baue Image
log_info "Baue MacReplay Image (Legacy Docker Build)..."
if [[ "$DOCKERFILE" == "Dockerfile-unraid" ]]; then
    docker build -t macreplay:unraid -f Dockerfile-unraid --build-arg PUID=99 --build-arg PGID=100 .
else
    docker build -t macreplay:unraid -f Dockerfile .
fi

# Starte Container
log_info "Starte MacReplay Container..."
docker run -d \
    --name macreplay \
    --hostname macreplay \
    --restart unless-stopped \
    --network bridge \
    -p 8001:8001 \
    -v "${DATA_DIR}:/app/data" \
    -v "${LOGS_DIR}:/app/logs" \
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
    echo -e "${GREEN}Nützliche Befehle:${NC}"
    echo "  Status:    docker ps --filter name=macreplay"
    echo "  Logs:      docker logs macreplay -f"
    echo "  Stoppen:   docker stop macreplay"
    echo "  Starten:   docker start macreplay"
    echo "  Neustart:  docker restart macreplay"
    echo "  Entfernen: docker stop macreplay && docker rm macreplay"
    echo "  Update:    $0  # Script erneut ausführen"
    
else
    log_error "❌ Fehler beim Starten des Containers!"
    log_info "Container-Logs:"
    docker logs macreplay
    exit 1
fi

echo
log_info "🎉 Installation erfolgreich abgeschlossen!"