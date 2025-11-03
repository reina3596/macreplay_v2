#!/bin/bash

# MacReplay Unraid Setup Script
# Dieses Script hilft bei der Installation von MacReplay auf Unraid

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
echo "     MacReplay Unraid Setup Script"
echo "=================================================="
echo -e "${NC}"

# Konfiguration
APPDATA_DIR="/mnt/user/appdata/macreplay"
SOURCE_DIR="$APPDATA_DIR/source"
DATA_DIR="$APPDATA_DIR/data"
LOGS_DIR="$APPDATA_DIR/logs"

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

# Erstelle Verzeichnisstruktur
create_directories() {
    log_info "Erstelle Verzeichnisstruktur..."
    
    mkdir -p "$SOURCE_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOGS_DIR"
    
    # Setze Berechtigungen (nobody:users = 99:100)
    chown -R 99:100 "$APPDATA_DIR"
    chmod -R 755 "$APPDATA_DIR"
    
    log_info "Verzeichnisse erstellt: $APPDATA_DIR"
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
        log_warn "Docker Compose nicht gefunden. Installiere Docker Compose..."
        install_docker_compose
    else
        log_info "Docker Compose gefunden: $(docker-compose --version)"
    fi
}

# Installiere Docker Compose
install_docker_compose() {
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_info "Docker Compose installiert: $COMPOSE_VERSION"
}

# Kopiere MacReplay-Dateien (lokale Installation)
copy_files() {
    log_info "Kopiere MacReplay-Dateien..."
    
    # Überprüfe ob wir bereits im Zielverzeichnis sind
    CURRENT_DIR=$(pwd)
    if [[ "$CURRENT_DIR" == "$SOURCE_DIR" ]]; then
        log_info "Script wird bereits im Zielverzeichnis ausgeführt - überspringe Kopiervorgang."
        
        # Überprüfe ob alle notwendigen Dateien vorhanden sind
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
            exit 1
        fi
        
        log_info "Alle notwendigen Dateien sind vorhanden."
        return
    fi
    
    # Überprüfe ob wir im richtigen Verzeichnis sind
    if [[ ! -f "docker-compose-unraid.yml" ]]; then
        log_error "docker-compose-unraid.yml nicht im aktuellen Verzeichnis gefunden."
        log_error "Bitte führen Sie dieses Script im MacReplay-Quellverzeichnis aus."
        log_error "Stellen Sie sicher, dass alle lokalen MacReplay-Dateien hier sind."
        exit 1
    fi
    
    # Kopiere alle notwendigen Dateien
    cp docker-compose-unraid.yml "$SOURCE_DIR/"
    [[ -f "Dockerfile-unraid" ]] && cp Dockerfile-unraid "$SOURCE_DIR/"
    cp app-docker.py "$SOURCE_DIR/"
    cp stb.py "$SOURCE_DIR/"
    cp requirements.txt "$SOURCE_DIR/"
    
    # Kopiere Verzeichnisse
    cp -r templates "$SOURCE_DIR/"
    cp -r static "$SOURCE_DIR/"
    
    # Kopiere optionale Dateien
    [[ -f "README-Unraid.md" ]] && cp README-Unraid.md "$SOURCE_DIR/"
    [[ -f "unraid-template.xml" ]] && cp unraid-template.xml "$SOURCE_DIR/"
    [[ -f "README-Lokale-Installation.md" ]] && cp README-Lokale-Installation.md "$SOURCE_DIR/"
    
    log_info "Lokale Dateien nach $SOURCE_DIR kopiert."
}

# Baue Docker Image
build_image() {
    log_info "Baue MacReplay Docker Image..."
    
    cd "$SOURCE_DIR"
    
    # Überprüfe ob ein Dockerfile vorhanden ist
    if [[ -f "Dockerfile-unraid" ]] || [[ -f "Dockerfile" ]]; then
        log_info "Dockerfile gefunden - baue lokales Image..."
        docker-compose -f docker-compose-unraid.yml build --no-cache
    else
        log_info "Kein Dockerfile gefunden - verwende Pre-Built Image..."
        # Für den Fall, dass ein fertiges Image verwendet wird
        docker-compose -f docker-compose-unraid.yml pull 2>/dev/null || true
    fi
    
    log_info "Docker Image-Vorbereitung abgeschlossen."
}

# Starte Container
start_container() {
    log_info "Starte MacReplay Container..."
    
    cd "$SOURCE_DIR"
    docker-compose -f docker-compose-unraid.yml up -d
    
    log_info "Container gestartet. Überprüfe Status..."
    sleep 5
    
    if docker-compose -f docker-compose-unraid.yml ps | grep -q "Up"; then
        log_info "MacReplay Container läuft erfolgreich!"
        log_info "Web-UI verfügbar unter: http://$(hostname -I | awk '{print $1}'):8001"
    else
        log_error "Fehler beim Starten des Containers. Überprüfe die Logs:"
        docker-compose -f docker-compose-unraid.yml logs
    fi
}

# Zeige Zusammenfassung
show_summary() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "     Installation abgeschlossen!"
    echo "=================================================="
    echo -e "${NC}"
    echo
    echo -e "${GREEN}Verzeichnisse:${NC}"
    echo "  Quellcode: $SOURCE_DIR"
    echo "  Daten:     $DATA_DIR"
    echo "  Logs:      $LOGS_DIR"
    echo
    echo -e "${GREEN}Nützliche Befehle:${NC}"
    echo "  Status:    cd $SOURCE_DIR && docker-compose -f docker-compose-unraid.yml ps"
    echo "  Logs:      cd $SOURCE_DIR && docker-compose -f docker-compose-unraid.yml logs -f"
    echo "  Stoppen:   cd $SOURCE_DIR && docker-compose -f docker-compose-unraid.yml down"
    echo "  Starten:   cd $SOURCE_DIR && docker-compose -f docker-compose-unraid.yml up -d"
    echo "  Update:    cd $SOURCE_DIR && docker-compose -f docker-compose-unraid.yml build --no-cache && docker-compose -f docker-compose-unraid.yml up -d"
    echo
    echo -e "${GREEN}Web-Interface:${NC}"
    echo "  URL: http://$(hostname -I | awk '{print $1}'):8001"
    echo
}

# Hauptfunktion
main() {
    log_info "Starte MacReplay Unraid Installation..."
    
    check_unraid
    check_docker
    check_docker_compose
    create_directories
    copy_files
    build_image
    start_container
    show_summary
    
    log_info "Installation erfolgreich abgeschlossen!"
}

# Hilfe anzeigen
show_help() {
    echo "MacReplay Unraid Setup Script"
    echo
    echo "Verwendung: $0 [OPTION]"
    echo
    echo "Optionen:"
    echo "  -h, --help     Zeige diese Hilfe an"
    echo "  --uninstall    Deinstalliere MacReplay"
    echo "  --update       Update MacReplay"
    echo
}

# Deinstallation
uninstall() {
    log_warn "Deinstalliere MacReplay..."
    
    if [[ -d "$SOURCE_DIR" ]]; then
        cd "$SOURCE_DIR"
        docker-compose -f docker-compose-unraid.yml down 2>/dev/null || true
        docker rmi macreplay:unraid 2>/dev/null || true
    fi
    
    read -p "Möchten Sie auch die Daten löschen? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$APPDATA_DIR"
        log_info "MacReplay vollständig deinstalliert (inklusive Daten)."
    else
        rm -rf "$SOURCE_DIR"
        log_info "MacReplay deinstalliert (Daten beibehalten)."
    fi
}

# Update (lokale Dateien)
update() {
    log_info "Update MacReplay mit lokalen Dateien..."
    
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "MacReplay ist nicht installiert. Führen Sie zuerst die Installation aus."
        exit 1
    fi
    
    log_warn "WICHTIG: Stellen Sie sicher, dass Sie die neuesten MacReplay-Dateien"
    log_warn "in das aktuelle Verzeichnis kopiert haben, bevor Sie das Update starten."
    
    read -p "Haben Sie die neuesten Dateien bereitgestellt? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update abgebrochen. Bitte kopieren Sie zuerst die neuen Dateien."
        exit 0
    fi
    
    copy_files
    build_image
    start_container
    
    log_info "Update abgeschlossen!"
}

# Parameter verarbeiten
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    --uninstall)
        uninstall
        exit 0
        ;;
    --update)
        update
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