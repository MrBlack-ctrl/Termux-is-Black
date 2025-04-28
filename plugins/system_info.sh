#!/bin/bash

# Plugin für Termux-is-Black: Systeminformationen anzeigen
# Datei: plugins/system_info.sh
# Beschreibung: Zeigt CPU-, Speicher-, Netzwerk- und Paketinformationen für Termux
# Autor: Mr.Black (https://t.me/MrBlackHead01)
# Kompatibel mit Termux-is-Black Plugin-System

# Farben (passend zu Termux-is-Black Themes)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

# Logging-Funktion (kompatibel mit startup.sh)
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$HOME/termux_startup.log"
    echo "[$timestamp] [$level] [system_info] $message" >> "$log_file"
}

# Hauptfunktion für das Plugin
run_system_info() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🖥️ Systeminformationen      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # CPU-Informationen
    echo -e "${YELLOW}${BOLD}${UNDERLINE}CPU-Informationen:${NC}"
    if command -v lscpu &> /dev/null; then
        CPU_MODEL=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
        CPU_CORES=$(lscpu | grep "CPU(s):" | head -1 | awk -F: '{print $2}' | xargs)
        echo -e " ${GREEN}📏 Modell:${NC} $CPU_MODEL"
        echo -e " ${GREEN}🔢 Kerne:${NC} $CPU_CORES"
    else
        echo -e " ${YELLOW}⚠️ lscpu nicht installiert (pkg install util-linux)${NC}"
        log_message "WARNING" "lscpu nicht verfügbar."
    fi
    if command -v top &> /dev/null; then
        CPU_USAGE=$(top -bn1 | grep "CPU:" | awk '{print $2}' | cut -d% -f1)
        echo -e " ${GREEN}⚙️ Auslastung:${NC} ${CPU_USAGE}%"
    else
        echo -e " ${YELLOW}⚠️ top nicht installiert (pkg install procps)${NC}"
        log_message "WARNING" "top nicht verfügbar."
    fi
    echo ""

    # Speicherinformationen
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Speicherinformationen:${NC}"
    if command -v free &> /dev/null; then
        MEMORY=$(free -h | awk '/^Mem:/ {print $4 "/" $2}')
        echo -e " ${GREEN}🧠 RAM:${NC} $MEMORY frei"
    else
        echo -e " ${YELLOW}⚠️ free nicht installiert (pkg install procps)${NC}"
        log_message "WARNING" "free nicht verfügbar."
    fi
    STORAGE=$(df -h /data/data/com.termux/files/home | awk 'NR==2{print $4 "/" $2}')
    echo -e " ${GREEN}💾 Speicher (~):${NC} $STORAGE frei"
    echo ""

    # Netzwerkinformationen
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Netzwerkinformationen:${NC}"
    LOCAL_IP=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null || ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    if [ -n "$LOCAL_IP" ]; then
        echo -e " ${GREEN}🌐 Lokale IP:${NC} $LOCAL_IP"
    else
        echo -e " ${YELLOW}⚠️ Keine Netzwerkverbindung erkannt${NC}"
        log_message "WARNING" "Keine lokale IP erkannt."
    fi
    if command -v ifconfig &> /dev/null; then
        GATEWAY=$(ip r | grep default | awk '{print $3}')
        echo -e " ${GREEN}🚪 Gateway:${NC} $GATEWAY"
    else
        echo -e " ${YELLOW}⚠️ ifconfig nicht installiert (pkg install net-tools)${NC}"
        log_message "WARNING" "ifconfig nicht verfügbar."
    fi
    echo ""

    # Installierte Pakete
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Installierte Pakete:${NC}"
    if command -v pkg &> /dev/null; then
        PKG_COUNT=$(pkg list-installed | wc -l)
        echo -e " ${GREEN}📦 Anzahl Pakete:${NC} $((PKG_COUNT - 1)) (exkl. Header)"
        read -p "$(echo -e "${BLUE}Liste aller Pakete anzeigen? (j/N): ${NC}")" show_pkgs
        if [[ "$show_pkgs" =~ ^[jJ](a)?$ ]]; then
            echo -e "${CYAN}Installierte Pakete:${NC}"
            pkg list-installed | tail -n +2 | awk -F/ '{print " - " $1}' | sort
        fi
    else
        echo -e " ${YELLOW}⚠️ pkg-Befehl nicht verfügbar${NC}"
        log_message "ERROR" "pkg-Befehl nicht verfügbar."
    fi
    echo ""

    log_message "INFO" "Systeminformationen erfolgreich angezeigt."
    echo -e "${GREEN}${BOLD}✅ Systeminformationen abgeschlossen.${NC}"
    read -p "Drücke Enter, um zurückzukehren..."
}

# Plugin-Version (für spätere Erweiterungen)
PLUGIN_VERSION="1.0.0"

# Logging beim Laden des Plugins
log_message "INFO" "Plugin system_info.sh (v$PLUGIN_VERSION) geladen."