#!/bin/bash

# Plugin für Termux-is-Black: Datei-Bereiniger
# Datei: plugins/file_cleaner.sh
# Beschreibung: Findet und löscht temporäre Dateien, leere Verzeichnisse und doppelte Dateien im Termux-Dateisystem
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
    echo "[$timestamp] [$level] [file_cleaner] $message" >> "$log_file"
}

# Standard-Bereinigungspfad
CLEAN_DIR="$HOME"
# Konfigurationsdatei für Plugin-spezifische Einstellungen
CONFIG_FILE="$HOME/.termux_startup.conf"

# Temporäre Dateien bereinigen
clean_temp_files() {
    echo -e "${CYAN}🧹 Suche nach temporären Dateien in $CLEAN_DIR...${NC}"
    local temp_files=$(find "$CLEAN_DIR" -type f \( -name "*.tmp" -o -name "*.log" -o -name "*.bak" \) 2>/dev/null)
    if [ -z "$temp_files" ]; then
        echo -e "${YELLOW}⚠️ Keine temporären Dateien gefunden.${NC}"
        log_message "INFO" "Keine temporären Dateien in $CLEAN_DIR gefunden."
        return 0
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Gefundene temporäre Dateien:${NC}"
    echo "$temp_files" | while read -r file; do
        echo -e " ${GREEN}📄 $file${NC}"
    done
    read -p "$(echo -e "${BLUE}Alle temporären Dateien löschen? (j/N): ${NC}")" confirm
    if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
        echo "$temp_files" | while read -r file; do
            if rm -f "$file"; then
                echo -e "${GREEN}✅ Gelöscht: $file${NC}"
                log_message "INFO" "Temporäre Datei gelöscht: $file"
            else
                echo -e "${RED}❌ Fehler beim Löschen: $file${NC}"
                log_message "ERROR" "Fehler beim Löschen der Datei: $file"
            fi
        done
    else
        echo -e "${CYAN}Abgebrochen.${NC}"
        log_message "INFO" "Löschen temporärer Dateien abgebrochen."
    fi
    return 0
}

# Leere Verzeichnisse bereinigen
clean_empty_dirs() {
    echo -e "${CYAN}🧹 Suche nach leeren Verzeichnissen in $CLEAN_DIR...${NC}"
    local empty_dirs=$(find "$CLEAN_DIR" -type d -empty 2>/dev/null)
    if [ -z "$empty_dirs" ]; then
        echo -e "${YELLOW}⚠️ Keine leeren Verzeichnisse gefunden.${NC}"
        log_message "INFO" "Keine leeren Verzeichnisse in $CLEAN_DIR gefunden."
        return 0
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Gefundene leere Verzeichnisse:${NC}"
    echo "$empty_dirs" | while read -r dir; do
        echo -e " ${GREEN}📁 $dir${NC}"
    done
    read -p "$(echo -e "${BLUE}Alle leeren Verzeichnisse löschen? (j/N): ${NC}")" confirm
    if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
        echo "$empty_dirs" | while read -r dir; do
            if rmdir "$dir" 2>/dev/null; then
                echo -e "${GREEN}✅ Gelöscht: $dir${NC}"
                log_message "INFO" "Leeres Verzeichnis gelöscht: $dir"
            else
                echo -e "${RED}❌ Fehler beim Löschen: $dir${NC}"
                log_message "ERROR" "Fehler beim Löschen des Verzeichnisses: $dir"
            fi
        done
    else
        echo -e "${CYAN}Abgebrochen.${NC}"
        log_message "INFO" "Löschen leerer Verzeichnisse abgebrochen."
    fi
    return 0
}

# Doppelte Dateien finden und löschen
clean_duplicate_files() {
    if ! command -v md5sum &> /dev/null; then
        echo -e "${YELLOW}⚠️ md5sum nicht installiert (pkg install coreutils)${NC}"
        log_message "WARNING" "md5sum nicht verfügbar."
        return 1
    fi

    echo -e "${CYAN}🧹 Suche nach doppelten Dateien in $CLEAN_DIR...${NC}"
    local duplicates=$(find "$CLEAN_DIR" -type f -exec md5sum {} \; 2>/dev/null | sort | uniq -D -w 32 | awk '{print $2}' | sort -u)
    if [ -z "$duplicates" ]; then
        echo -e "${YELLOW}⚠️ Keine doppelten Dateien gefunden.${NC}"
        log_message "INFO" "Keine doppelten Dateien in $CLEAN_DIR gefunden."
        return 0
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Gefundene doppelte Dateien:${NC}"
    local temp_file=$(mktemp)
    find "$CLEAN_DIR" -type f -exec md5sum {} \; 2>/dev/null | sort > "$temp_file"
    local last_hash=""
    local files=()
    while read -r hash file; do
        if [ "$hash" = "$last_hash" ]; then
            files+=("$file")
            echo -e " ${GREEN}📄 $file${NC}"
        else
            if [ ${#files[@]} -gt 1 ]; then
                echo -e " ${YELLOW}🔄 Doppelte Dateien mit Hash $last_hash:${NC}"
                for f in "${files[@]}"; do
                    echo -e "  ${GREEN}- $f${NC}"
                done
            fi
            files=("$file")
            last_hash="$hash"
        fi
    done < "$temp_file"
    rm -f "$temp_file"

    read -p "$(echo -e "${BLUE}Doppelte Dateien löschen (ältere Dateien behalten)? (j/N): ${NC}")" confirm
    if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
        find "$CLEAN_DIR" -type f -exec md5sum {} \; 2>/dev/null | sort | uniq -w 32 -D | awk '{print $2}' | while read -r file; do
            # Älteste Datei pro Hash behalten
            local hash=$(md5sum "$file" | awk '{print $1}')
            local oldest_file=$(find "$CLEAN_DIR" -type f -exec md5sum {} \; 2>/dev/null | grep "$hash" | sort -k3 | head -1 | awk '{print $2}')
            if [ "$file" != "$oldest_file" ]; then
                if rm -f "$file"; then
                    echo -e "${GREEN}✅ Gelöscht: $file${NC}"
                    log_message "INFO" "Doppelte Datei gelöscht: $file"
                else
                    echo -e "${RED}❌ Fehler beim Löschen: $file${NC}"
                    log_message "ERROR" "Fehler beim Löschen der Datei: $file"
                fi
            fi
        done
    else
        echo -e "${CYAN}Abgebrochen.${NC}"
        log_message "INFO" "Löschen doppelter Dateien abgebrochen."
    fi
    return 0
}

# Hauptmenü
run_file_cleaner() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🧹 Datei-Bereiniger      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Bereinigungspfad aus Konfigurationsdatei laden, falls verfügbar
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$CLEAN_DIR" ] && CLEAN_DIR="$CLEAN_DIR"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Temporäre Dateien bereinigen"
        echo -e " ${GREEN}2)${NC} Leere Verzeichnisse bereinigen"
        echo -e " ${GREEN}3)${NC} Doppelte Dateien bereinigen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                clean_temp_files
                echo ""
                ;;
            2)
                clean_empty_dirs
                echo ""
                ;;
            3)
                clean_duplicate_files
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Datei-Bereiniger beendet.${NC}"
                log_message "INFO" "Datei-Bereiniger beendet."
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
log_message "INFO" "Plugin file_cleaner.sh (v$PLUGIN_VERSION) geladen."