#!/bin/bash

# MacReplay Unraid Quick Setup (für Ausführung im Zielverzeichnis)
# Dieses Script kann direkt in /mnt/user/appdata/macreplay/source/ ausgeführt werden

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
echo "     MacReplay Unraid Quick Setup"
echo "=================================================="
echo -e "${NC}"

# Konfiguration
CURRENT_DIR=$(pwd)
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

# Überprüfe ob wir auf Unraid sind
check_unraid() {
    if [[ ! -d "/mnt/user" ]]; then
        log_error "Dieses Script ist für Unraid konzipiert. /mnt/user wurde nicht gefunden."
        exit 1
    fi
    log_info "Unraid-Umgebung erkannt."
}

# Erstelle Daten-Verzeichnisse
create_directories() {
    log_info "Erstelle Daten-Verzeichnisse..."
    
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOGS_DIR"
    
    # Setze Berechtigungen (nobody:users = 99:100)
    chown -R 99:100 "$DATA_DIR" "$LOGS_DIR"
    chmod -R 755 "$DATA_DIR" "$LOGS_DIR"
    
    log_info "Daten-Verzeichnisse erstellt."
}

# Überprüfe notwendige Dateien
check_files() {
    log_info "Überprüfe notwendige Dateien..."
    
    local missing_files=0
    
    if [[ ! -f "docker-compose-unraid.yml" ]]; then
        log_error "docker-compose-unraid.yml fehlt!"
        missing_files=1
    fi
    
    if [[ ! -f "app-docker.py" ]]; then
        log_error "app-docker.py fehlt!"
        missing_files=1
    fi
    
    if [[ ! -f "stb.py" ]]; then
        log_error "stb.py fehlt!"
        missing_files=1
    fi
    
    if [[ ! -f "requirements.txt" ]]; then
        log_error "requirements.txt fehlt!"
        missing_files=1
    fi
    
    if [[ ! -d "templates" ]]; then
        log_error "templates/ Verzeichnis fehlt!"
        missing_files=1
    fi
    
    if [[ ! -d "static" ]]; then
        log_error "static/ Verzeichnis fehlt!"
        missing_files=1
    fi
    
    if [[ $missing_files -eq 1 ]]; then
        log_error "Nicht alle notwendigen Dateien sind vorhanden!"
        log_info "Benötigte Dateien:"
        log_info "  - docker-compose-unraid.yml"
        log_info "  - app-docker.py"
        log_info "  - stb.py"
        log_info "  - requirements.txt"
        log_info "  - templates/ (Verzeichnis)"
        log_info "  - static/ (Verzeichnis)"
        exit 1
    fi
    
    log_info "Alle notwendigen Dateien sind vorhanden."
}

# Überprüfe Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker ist nicht installiert oder nicht im PATH."
        exit 1
    fi
    log_info "Docker gefunden: $(docker --version)"
}

# Überprüfe Docker Compose
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose ist nicht installiert oder nicht im PATH."
        exit 1
    fi
    log_info "Docker Compose gefunden: $(docker-compose --version)"
}

# Stoppe vorhandenen Container
stop_existing() {
    log_info "Stoppe vorhandenen Container (falls vorhanden)..."
    docker stop macreplay 2>/dev/null || true
    docker rm macreplay 2>/dev/null || true
    # Auch docker-compose down versuchen
    docker-compose -f docker-compose-unraid.yml down 2>/dev/null || true
}

# Starte Container
start_container() {
    log_info "Starte MacReplay Container..."
    
    # Immer Legacy-Build verwenden da Buildx-Probleme auf Unraid häufig sind
    log_warn "Verwende Legacy Docker Build (umgeht Buildx-Probleme)..."
    use_legacy_build
    
    log_info "Container gestartet. Überprüfe Status..."
    sleep 5
    
    if docker ps | grep -q "macreplay"; then
        log_info "MacReplay Container läuft erfolgreich!"
        local ip=$(hostname -I | awk '{print $1}')
        log_info "Web-UI verfügbar unter: http://${ip}:8001"
    else
        log_error "Fehler beim Starten des Containers. Überprüfe die Logs:"
        docker logs macreplay 2>/dev/null || log_error "Container nicht gefunden"
        exit 1
    fi
}

# Legacy Build Funktion
use_legacy_build() {
    if [[ -f "Dockerfile-unraid" ]]; then
        log_info "Baue Image mit legacy docker build (Dockerfile-unraid)..."
        
        # Bestimme Image-Namen
        local image_name="macreplay:unraid"
        
        log_info "Baue Image: $image_name"
        docker build -t "$image_name" -f Dockerfile-unraid --build-arg PUID=99 --build-arg PGID=100 .
        
        # Starte Container direkt mit docker run
        log_info "Starte Container mit docker run..."
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
            "$image_name"
            
    elif [[ -f "Dockerfile" ]]; then
        log_info "Baue Image mit legacy docker build (Dockerfile)..."
        docker build -t macreplay:unraid .
        
        # Starte Container direkt mit docker run
        log_info "Starte Container mit docker run..."
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
    else
        log_info "Kein Dockerfile gefunden - verwende Pre-Built Image..."
        docker-compose -f docker-compose-unraid.yml up -d
    fi
}

# Zeige Status
show_status() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "     MacReplay Status"
    echo "=================================================="
    echo -e "${NC}"
    
    docker-compose -f docker-compose-unraid.yml ps
    
    echo
    echo -e "${GREEN}Nützliche Befehle:${NC}"
    echo "  Status:    docker-compose -f docker-compose-unraid.yml ps"
    echo "  Logs:      docker-compose -f docker-compose-unraid.yml logs -f"
    echo "  Stoppen:   docker-compose -f docker-compose-unraid.yml down"
    echo "  Starten:   docker-compose -f docker-compose-unraid.yml up -d"
    echo "  Neustart:  docker-compose -f docker-compose-unraid.yml restart"
    echo
}

# Hauptfunktion
main() {
    log_info "Starte MacReplay Quick Setup..."
    
    check_unraid
    check_docker
    check_docker_compose
    check_files
    create_directories
    stop_existing
    start_container
    show_status
    
    log_info "Setup erfolgreich abgeschlossen!"
}

# Hilfe anzeigen
show_help() {
    echo "MacReplay Unraid Quick Setup Script"
    echo
    echo "Verwendung: $0 [OPTION]"
    echo
    echo "Optionen:"
    echo "  -h, --help     Zeige diese Hilfe an"
    echo "  --start        Starte Container"
    echo "  --stop         Stoppe Container"
    echo "  --restart      Neustart Container"
    echo "  --status       Zeige Container-Status"
    echo "  --logs         Zeige Container-Logs"
    echo "  --update       Update Container (rebuild)"
    echo
    echo "Dieses Script muss im Verzeichnis mit den MacReplay-Dateien ausgeführt werden."
}

# Parameter verarbeiten
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    --start)
        check_files
        docker-compose -f docker-compose-unraid.yml up -d
        exit 0
        ;;
    --stop)
        docker-compose -f docker-compose-unraid.yml down
        exit 0
        ;;
    --restart)
        docker-compose -f docker-compose-unraid.yml restart
        exit 0
        ;;
    --status)
        docker-compose -f docker-compose-unraid.yml ps
        exit 0
        ;;
    --logs)
        docker-compose -f docker-compose-unraid.yml logs -f
        exit 0
        ;;
    --update)
        check_files
        docker stop macreplay 2>/dev/null || true
        docker rm macreplay 2>/dev/null || true
        
        if [[ -f "Dockerfile-unraid" ]]; then
            log_info "Rebuilding with Dockerfile-unraid..."
            if docker buildx version &>/dev/null; then
                docker-compose -f docker-compose-unraid.yml build --no-cache
                docker-compose -f docker-compose-unraid.yml up -d
            else
                docker build -t macreplay:unraid -f Dockerfile-unraid --build-arg PUID=99 --build-arg PGID=100 --no-cache .
                docker run -d --name macreplay --restart unless-stopped -p 8001:8001 \
                    -v /mnt/user/appdata/macreplay/data:/app/data \
                    -v /mnt/user/appdata/macreplay/logs:/app/logs \
                    -e PUID=99 -e PGID=100 -e TZ=Europe/Berlin -e PYTHONUNBUFFERED=1 \
                    macreplay:unraid
            fi
        elif [[ -f "Dockerfile" ]]; then
            log_info "Rebuilding with Dockerfile..."
            docker build -t macreplay:unraid --no-cache .
            docker run -d --name macreplay --restart unless-stopped -p 8001:8001 \
                -v /mnt/user/appdata/macreplay/data:/app/data \
                -v /mnt/user/appdata/macreplay/logs:/app/logs \
                -e PUID=99 -e PGID=100 -e TZ=Europe/Berlin -e PYTHONUNBUFFERED=1 \
                macreplay:unraid
        else
            docker-compose -f docker-compose-unraid.yml up -d
        fi
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unbekannte Option: $1"
        show_help
        exit 1
        ;;
esac