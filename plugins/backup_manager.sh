#!/bin/bash

# Plugin für Termux-is-Black: Backup-Manager
# Datei: plugins/backup_manager.sh
# Beschreibung: Erstellt, verwaltet und stellt Backups des Termux-Home-Verzeichnisses oder spezifischer Ordner wieder her
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
    echo "[$timestamp] [$level] [backup_manager] $message" >> "$log_file"
}

# Standard-Backup-Verzeichnis
BACKUP_DIR="$HOME/storage/shared/termux_backups"
# Backup-Quelle (kann über ~/.termux_startup.conf überschrieben werden)
BACKUP_SOURCE="$HOME"
# Konfigurationsdatei für Plugin-spezifische Einstellungen
CONFIG_FILE="$HOME/.termux_startup.conf"

# Backup-Verzeichnis initialisieren
init_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        if [ $? -eq 0 ]; then
            log_message "INFO" "Backup-Verzeichnis $BACKUP_DIR erstellt."
        else
            log_message "ERROR" "Konnte Backup-Verzeichnis $BACKUP_DIR nicht erstellen."
            echo -e "${RED}${BOLD}❌ Fehler: Konnte $BACKUP_DIR nicht erstellen.${NC}"
            return 1
        fi
    fi
    return 0
}

# Backup erstellen
create_backup() {
    init_backup_dir || return 1
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/termux_backup_$timestamp.tar.gz"
    
    echo -e "${CYAN}📁 Erstelle Backup von $BACKUP_SOURCE...${NC}"
    if tar -czf "$backup_file" -C "$(dirname $BACKUP_SOURCE)" "$(basename $BACKUP_SOURCE)" 2>/dev/null; then
        echo -e "${GREEN}${BOLD}✅ Backup erstellt: $backup_file${NC}"
        log_message "INFO" "Backup erstellt: $backup_file"
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Erstellen des Backups.${NC}"
        log_message "ERROR" "Fehler beim Erstellen des Backups: $backup_file"
        return 1
    fi
    return 0
}

# Backups auflisten
list_backups() {
    init_backup_dir || return 1
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare Backups:${NC}"
    if ls "$BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then
        local i=1
        for backup in "$BACKUP_DIR"/*.tar.gz; do
            echo -e " ${GREEN}[$i]${NC} $(basename "$backup") (${BLUE}$(stat -c %y "$backup" | cut -d' ' -f1)${NC})"
            ((i++))
        done
    else
        echo -e " ${YELLOW}⚠️ Keine Backups gefunden in $BACKUP_DIR${NC}"
        log_message "WARNING" "Keine Backups in $BACKUP_DIR gefunden."
    fi
}

# Backup löschen
delete_backup() {
    init_backup_dir || return 1
    local backups=("$BACKUP_DIR"/*.tar.gz)
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Keine Backups zum Löschen gefunden.${NC}"
        log_message "WARNING" "Keine Backups zum Löschen gefunden."
        return 1
    fi

    list_backups
    read -p "$(echo -e "${BLUE}Nummer des zu löschenden Backups (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#backups[@]} ]; then
        local backup_file="${backups[$index]}"
        echo -e "${CYAN}Lösche $backup_file...${NC}"
        if rm -f "$backup_file"; then
            echo -e "${GREEN}${BOLD}✅ Backup gelöscht: $backup_file${NC}"
            log_message "INFO" "Backup gelöscht: $backup_file"
        else
            echo -e "${RED}${BOLD}❌ Fehler beim Löschen des Backups.${NC}"
            log_message "ERROR" "Fehler beim Löschen des Backups: $backup_file"
            return 1
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Backup-Auswahl: $choice"
        return 1
    fi
    return 0
}

# Backup wiederherstellen
restore_backup() {
    init_backup_dir || return 1
    local backups=("$BACKUP_DIR"/*.tar.gz)
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Keine Backups zum Wiederherstellen gefunden.${NC}"
        log_message "WARNING" "Keine Backups zum Wiederherstellen gefunden."
        return 1
    fi

    list_backups
    read -p "$(echo -e "${BLUE}Nummer des wiederherzustellenden Backups (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#backups[@]} ]; then
        local backup_file="${backups[$index]}"
        echo -e "${CYAN}Stelle $backup_file wieder her...${NC}"
        read -p "$(echo -e "${YELLOW}⚠️ Warnung: Dies überschreibt Dateien in $BACKUP_SOURCE! Fortfahren? (j/N): ${NC}")" confirm
        if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
            if tar -xzf "$backup_file" -C "$(dirname $BACKUP_SOURCE)" 2>/dev/null; then
                echo -e "${GREEN}${BOLD}✅ Backup wiederhergestellt: $backup_file${NC}"
                log_message "INFO" "Backup wiederhergestellt: $backup_file"
            else
                echo -e "${RED}${BOLD}❌ Fehler beim Wiederherstellen des Backups.${NC}"
                log_message "ERROR" "Fehler beim Wiederherstellen des Backups: $backup_file"
                return 1
            fi
        else
            echo -e "${CYAN}Abgebrochen.${NC}"
            log_message "INFO" "Wiederherstellung abgebrochen."
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Backup-Auswahl: $choice"
        return 1
    fi
    return 0
}

# Hauptmenü
run_backup_manager() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      💾 Backup-Manager      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Backup-Quelle aus Konfigurationsdatei laden, falls verfügbar
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$BACKUP_SOURCE" ] && BACKUP_SOURCE="$BACKUP_SOURCE"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Backup erstellen"
        echo -e " ${GREEN}2)${NC} Backups auflisten"
        echo -e " ${GREEN}3)${NC} Backup löschen"
        echo -e " ${GREEN}4)${NC} Backup wiederherstellen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                create_backup
                echo ""
                ;;
            2)
                list_backups
                echo ""
                ;;
            3)
                delete_backup
                echo ""
                ;;
            4)
                restore_backup
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Backup-Manager beendet.${NC}"
                log_message "INFO" "Backup-Manager beendet."
                break
                ;;
            *)
                echo -e "${RED}${BOLD}❌ Ungültige Option. Bitte wähle 1-4 oder q.${NC}"
                log_message "WARNING" "Ungültige Option ausgewählt: $choice"
                echo ""
                ;;
        esac
    done
}

# Plugin-Version (für spätere Erweiterungen)
PLUGIN_VERSION="1.0.0"

# Logging beim Laden des Plugins
log_message "INFO" "Plugin backup_manager.sh (v$PLUGIN_VERSION) geladen."