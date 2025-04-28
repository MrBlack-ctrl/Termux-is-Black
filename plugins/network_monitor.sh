#!/bin/bash

# Plugin für Termux-is-Black: Netzwerk-Monitor
# Datei: plugins/network_monitor.sh
# Beschreibung: Überwacht und analysiert Netzwerkverbindungen, Bandbreite, offene Ports und aktive Verbindungen
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
    echo "[$timestamp] [$level] [network_monitor] $message" >> "$log_file"
}

# Netzwerkstatus anzeigen
show_network_status() {
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Netzwerkstatus:${NC}"
    LOCAL_IP=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null || ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    if [ -n "$LOCAL_IP" ]; then
        echo -e " ${GREEN}🌐 Lokale IP:${NC} $LOCAL_IP"
    else
        echo -e " ${YELLOW}⚠️ Keine Netzwerkverbindung erkannt${NC}"
        log_message "WARNING" "Keine lokale IP erkannt."
    fi

    GATEWAY=$(ip r | grep default | awk '{print $3}' 2>/dev/null)
    if [ -n "$GATEWAY" ]; then
        echo -e " ${GREEN}🚪 Gateway:${NC} $GATEWAY"
    else
        echo -e " ${YELLOW}⚠️ Gateway nicht gefunden${NC}"
        log_message "WARNING" "Gateway nicht gefunden."
    fi

    DNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1 2>/dev/null)
    if [ -n "$DNS" ]; then
        echo -e " ${GREEN}🔍 DNS:${NC} $DNS"
    else
        echo -e " ${YELLOW}⚠️ DNS nicht gefunden${NC}"
        log_message "WARNING" "DNS nicht gefunden."
    fi
    echo ""
}

# Geschwindigkeitstest
speed_test() {
    if command -v curl &> /dev/null; then
        echo -e "${CYAN}🚀 Führe Geschwindigkeitstest durch (Download von Testdatei)...${NC}"
        local start_time=$(date +%s)
        local output=$(curl -s -o /dev/null -w "%{speed_download}" http://speedtest.tele2.net/1MB.zip 2>/dev/null)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local speed_kbps=$(echo "$output / 1024" | bc -l | awk '{printf "%.2f", $0}')
        echo -e " ${GREEN}📥 Download-Geschwindigkeit:${NC} $speed_kbps KB/s"
        echo -e " ${GREEN}⏱️ Dauer:${NC} $duration Sekunden"
        log_message "INFO" "Geschwindigkeitstest: $speed_kbps KB/s in $duration Sekunden."
    else
        echo -e " ${YELLOW}⚠️ curl nicht installiert (pkg install curl)${NC}"
        log_message "WARNING" "curl nicht verfügbar."
    fi
    echo ""
}

# Offene Ports scannen
scan_ports() {
    if command -v nmap &> /dev/null; then
        echo -e "${CYAN}🔎 Scanne offene Ports im lokalen Netzwerk...${NC}"
        read -p "$(echo -e "${BLUE}Ziel-IP oder Subnetz (z.B. 192.168.1.0/24, leer für lokale IP): ${NC}")" target
        target=${target:-$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)}
        if [ -z "$target" ]; then
            echo -e " ${RED}${BOLD}❌ Kein Ziel angegeben oder lokale IP nicht gefunden.${NC}"
            log_message "ERROR" "Kein Ziel für Port-Scan angegeben."
            return 1
        fi
        echo -e "${CYAN}Scanne $target...${NC}"
        nmap -sS "$target" | grep -E '^[0-9]+/tcp' | while read -r line; do
            echo -e " ${GREEN}🔓 $line${NC}"
        done
        log_message "INFO" "Port-Scan für $target abgeschlossen."
    else
        echo -e " ${YELLOW}⚠️ nmap nicht installiert (pkg install nmap)${NC}"
        log_message "WARNING" "nmap nicht verfügbar."
    fi
    echo ""
}

# Aktive Verbindungen anzeigen
show_connections() {
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Aktive Netzwerkverbindungen:${NC}"
    if command -v ss &> /dev/null; then
        ss -tuln | grep -E 'LISTEN|ESTAB' | while read -r line; do
            echo -e " ${GREEN}🔗 $line${NC}"
        done
        log_message "INFO" "Aktive Verbindungen mit ss angezeigt."
    elif command -v netstat &> /dev/null; then
        netstat -tuln | grep -E 'LISTEN|ESTABLISHED' | while read -r line; do
            echo -e " ${GREEN}🔗 $line${NC}"
        done
        log_message "INFO" "Aktive Verbindungen mit netstat angezeigt."
    else
        echo -e " ${YELLOW}⚠️ Weder ss noch netstat installiert (pkg install net-tools oder iproute2)${NC}"
        log_message "WARNING" "ss oder netstat nicht verfügbar."
    fi
    echo ""
}

# Hauptmenü
run_network_monitor() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🌐 Netzwerk-Monitor      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Netzwerkstatus anzeigen"
        echo -e " ${GREEN}2)${NC} Geschwindigkeitstest"
        echo -e " ${GREEN}3)${NC} Offene Ports scannen"
        echo -e " ${GREEN}4)${NC} Aktive Verbindungen anzeigen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                show_network_status
                ;;
            2)
                speed_test
                ;;
            3)
                scan_ports
                ;;
            4)
                show_connections
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Netzwerk-Monitor beendet.${NC}"
                log_message "INFO" "Netzwerk-Monitor beendet."
                break
                ;;
            *)
                echo -e "${RED}${BOLD}❌ Ungültige Option. Bitte wähle 1-4 oder q.${NC}"
                log_message "WARNING" "Ungültige Option ausgewählt: $choice"
                echo ""
                ;;
        esac
        read -p "$(echo -e "${BLUE}Drücke Enter, um fortzufahren...${NC}")"
    done
}

# Plugin-Version (für spätere Erweiterungen)
PLUGIN_VERSION="1.0.0"

# Logging beim Laden des Plugins
log_message "INFO" "Plugin network_monitor.sh (v$PLUGIN_VERSION) geladen."