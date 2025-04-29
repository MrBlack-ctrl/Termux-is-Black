#!/bin/bash

# Plugin für Termux-is-Black: Telegram-Benachrichtiger
# Datei: plugins/telegram_notifier.sh
# Beschreibung: Sendet Benachrichtigungen an Telegram-Chats für Systemereignisse oder benutzerdefinierte Nachrichten
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
    echo "[$timestamp] [$level] [telegram_notifier] $message" >> "$log_file"
}

# Konfigurationsdatei für Telegram-Einstellungen
CONFIG_FILE="$HOME/.termux_startup.conf"
# Standard-Telegram-Bot-Token und Chat-ID (werden aus CONFIG_FILE überschrieben)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Telegram-Konfiguration laden oder einrichten
setup_telegram() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${YELLOW}${BOLD}${UNDERLINE}Telegram-Konfiguration:${NC}"
        echo -e "${CYAN}Bitte richte einen Telegram-Bot ein:${NC}"
        echo -e "${CYAN}1. Sprich mit @BotFather auf Telegram und erstelle einen Bot.${NC}"
        echo -e "${CYAN}2. Kopiere den Bot-Token (z.B. 123456:ABC-DEF).${NC}"
        echo -e "${CYAN}3. Finde die Chat-ID (z.B. mit @GetIDsBot).${NC}"
        read -p "$(echo -e "${BLUE}Bot-Token eingeben: ${NC}")" TELEGRAM_BOT_TOKEN
        read -p "$(echo -e "${BLUE}Chat-ID eingeben: ${NC}")" TELEGRAM_CHAT_ID

        if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
            echo -e "${RED}${BOLD}❌ Ungültige Eingaben. Konfiguration abgebrochen.${NC}"
            log_message "ERROR" "Ungültige Telegram-Konfiguration."
            return 1
        fi

        # Konfiguration speichern
        echo "TELEGRAM_BOT_TOKEN='$TELEGRAM_BOT_TOKEN'" >> "$CONFIG_FILE"
        echo "TELEGRAM_CHAT_ID='$TELEGRAM_CHAT_ID'" >> "$CONFIG_FILE"
        echo -e "${GREEN}${BOLD}✅ Telegram-Konfiguration gespeichert in $CONFIG_FILE${NC}"
        log_message "INFO" "Telegram-Konfiguration gespeichert."
    fi
    return 0
}

# Benachrichtigung senden
send_notification() {
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}⚠️ curl nicht installiert (pkg install curl)${NC}"
        log_message "WARNING" "curl nicht verfügbar."
        return 1
    fi

    setup_telegram || return 1
    read -p "$(echo -e "${BLUE}Nachricht eingeben (oder leer für Standardnachricht): ${NC}")" message
    message=${message:-"Termux-is-Black: Systembenachrichtigung von $(whoami) am $(date '+%Y-%m-%d %H:%M:%S')"}
    
    echo -e "${CYAN}📩 Sende Nachricht an Telegram...${NC}"
    local api_url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
    if curl -s -X POST "$api_url" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$message" >/dev/null; then
        echo -e "${GREEN}${BOLD}✅ Nachricht gesendet: $message${NC}"
        log_message "INFO" "Nachricht gesendet: $message"
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Senden der Nachricht.${NC}"
        log_message "ERROR" "Fehler beim Senden der Nachricht: $message"
        return 1
    fi
    return 0
}

# Systemstatus-Benachrichtigung senden
send_system_status() {
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}⚠️ curl nicht installiert (pkg install curl)${NC}"
        log_message "WARNING" "curl nicht verfügbar."
        return 1
    fi

    setup_telegram || return 1
    local status="Termux-is-Black Systemstatus:\n"
    status+="Benutzer: $(whoami)\n"
    status+="Zeit: $(date '+%Y-%m-%d %H:%M:%S')\n"
    status+="Speicher: $(df -h $HOME | tail -1 | awk '{print $4}') frei\n"
    status+="CPU: $(top -bn1 | head -n 3 | grep '%cpu' | awk '{print $2}')% genutzt"

    echo -e "${CYAN}📩 Sende Systemstatus an Telegram...${NC}"
    local api_url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
    if curl -s -X POST "$api_url" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$status" >/dev/null; then
        echo -e "${GREEN}${BOLD}✅ Systemstatus gesendet:${NC}"
        echo -e "${GREEN}$status${NC}"
        log_message "INFO" "Systemstatus gesendet."
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Senden des Systemstatus.${NC}"
        log_message "ERROR" "Fehler beim Senden des Systemstatus."
        return 1
    fi
    return 0
}

# Hauptmenü
run_telegram_notifier() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      📩 Telegram-Benachrichtiger      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Benachrichtigung senden"
        echo -e " ${GREEN}2)${NC} Systemstatus senden"
        echo -e " ${GREEN}3)${NC} Telegram-Konfiguration einrichten"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                send_notification
                echo ""
                ;;
            2)
                send_system_status
                echo ""
                ;;
            3)
                setup_telegram
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Telegram-Benachrichtiger beendet.${NC}"
                log_message "INFO" "Telegram-Benachrichtiger beendet."
                break
                ;;
            *)
                echo -e "${RED}${BOLD}❌ Ungültige Option. Bitte wähle 1-3 oder q.${NC}"
                log_message "WARNING" "Ungültige Option ausgewählt: $choice"
                echo ""
                ;;
        esac
    done
}

# Plugin-Version (für spätere Erweiterungen)
PLUGIN_VERSION="1.0.0"

# Logging beim Laden des Plugins
log_message "INFO" "Plugin telegram_notifier.sh (v$PLUGIN_VERSION) geladen."
