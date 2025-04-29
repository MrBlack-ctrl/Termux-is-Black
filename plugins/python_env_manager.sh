#!/bin/bash

# Plugin für Termux-is-Black: Python-Umgebungs-Manager
# Datei: plugins/python_env_manager.sh
# Beschreibung: Verwaltet virtuelle Python-Umgebungen (Erstellen, Aktivieren, Deaktivieren, Löschen)
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
    echo "[$timestamp] [$level] [python_env_manager] $message" >> "$log_file"
}

# Standard-Verzeichnis für virtuelle Umgebungen
VENV_DIR="$HOME/.venvs"
# Python-Befehl (aus ~/.termux_startup.conf oder Standard)
PYTHON_CMD="python3"
CONFIG_FILE="$HOME/.termux_startup.conf"

# Virtuelle Umgebungen initialisieren
init_venv_dir() {
    if [ ! -d "$VENV_DIR" ]; then
        mkdir -p "$VENV_DIR"
        if [ $? -eq 0 ]; then
            log_message "INFO" "Verzeichnis für virtuelle Umgebungen $VENV_DIR erstellt."
        else
            log_message "ERROR" "Konnte Verzeichnis $VENV_DIR nicht erstellen."
            echo -e "${RED}${BOLD}❌ Fehler: Konnte $VENV_DIR nicht erstellen.${NC}"
            return 1
        fi
    fi
    return 0
}

# Neue virtuelle Umgebung erstellen
create_venv() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    init_venv_dir || return 1
    read -p "$(echo -e "${BLUE}Name der virtuellen Umgebung (z.B. myproject): ${NC}")" venv_name
    if [ -z "$venv_name" ]; then
        echo -e "${RED}${BOLD}❌ Ungültiger Name.${NC}"
        log_message "ERROR" "Kein Name für virtuelle Umgebung angegeben."
        return 1
    fi

    local venv_path="$VENV_DIR/$venv_name"
    if [ -d "$venv_path" ]; then
        echo -e "${RED}${BOLD}❌ Virtuelle Umgebung '$venv_name' existiert bereits.${NC}"
        log_message "ERROR" "Virtuelle Umgebung $venv_name existiert bereits."
        return 1
    fi

    echo -e "${CYAN}🐍 Erstelle virtuelle Umgebung '$venv_name'...${NC}"
    if "$PYTHON_CMD" -m venv "$venv_path"; then
        echo -e "${GREEN}${BOLD}✅ Virtuelle Umgebung '$venv_name' erstellt: $venv_path${NC}"
        log_message "INFO" "Virtuelle Umgebung erstellt: $venv_path"
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Erstellen der virtuellen Umgebung.${NC}"
        log_message "ERROR" "Fehler beim Erstellen der virtuellen Umgebung: $venv_name"
        return 1
    fi
    return 0
}

# Virtuelle Umgebung aktivieren
activate_venv() {
    init_venv_dir || return 1
    local venvs=("$VENV_DIR"/*)
    if [ ${#venvs[@]} -eq 0 ] || [ "${venvs[0]}" = "$VENV_DIR/*" ]; then
        echo -e "${YELLOW}⚠️ Keine virtuellen Umgebungen gefunden in $VENV_DIR${NC}"
        log_message "WARNING" "Keine virtuellen Umgebungen gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare virtuelle Umgebungen:${NC}"
    local i=1
    for venv in "${venvs[@]}"; do
        echo -e " ${GREEN}[$i]${NC} $(basename "$venv")"
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer der zu aktivierenden Umgebung (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#venvs[@]} ]; then
        local venv_path="${venvs[$index]}"
        local venv_name=$(basename "$venv_path")
        echo -e "${CYAN}🐍 Aktiviere virtuelle Umgebung '$venv_name'...${NC}"
        echo -e "${GREEN}ℹ️ Führe 'source $venv_path/bin/activate' aus, um die Umgebung zu aktivieren.${NC}"
        echo -e "${GREEN}ℹ️ Verwende 'deactivate' zum Deaktivieren.${NC}"
        log_message "INFO" "Benutzer angewiesen, virtuelle Umgebung $venv_name zu aktivieren."
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Auswahl für virtuelle Umgebung: $choice"
        return 1
    fi
    return 0
}

# Virtuelle Umgebung löschen
delete_venv() {
    init_venv_dir || return 1
    local venvs=("$VENV_DIR"/*)
    if [ ${#venvs[@]} -eq 0 ] || [ "${venvs[0]}" = "$VENV_DIR/*" ]; then
        echo -e "${YELLOW}⚠️ Keine virtuellen Umgebungen gefunden in $VENV_DIR${NC}"
        log_message "WARNING" "Keine virtuellen Umgebungen gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare virtuelle Umgebungen:${NC}"
    local i=1
    for venv in "${venvs[@]}"; do
        echo -e " ${GREEN}[$i]${NC} $(basename "$venv")"
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer der zu löschenden Umgebung (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#venvs[@]} ]; then
        local venv_path="${venvs[$index]}"
        local venv_name=$(basename "$venv_path")
        read -p "$(echo -e "${YELLOW}⚠️ Warnung: '$venv_name' wird gelöscht! Fortfahren? (j/N): ${NC}")" confirm
        if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
            if rm -rf "$venv_path"; then
                echo -e "${GREEN}${BOLD}✅ Virtuelle Umgebung '$venv_name' gelöscht.${NC}"
                log_message "INFO" "Virtuelle Umgebung gelöscht: $venv_name"
            else
                echo -e "${RED}${BOLD}❌ Fehler beim Löschen der virtuellen Umgebung.${NC}"
                log_message "ERROR" "Fehler beim Löschen der virtuellen Umgebung: $venv_name"
                return 1
            fi
        else
            echo -e "${CYAN}Abgebrochen.${NC}"
            log_message "INFO" "Löschen der virtuellen Umgebung $venv_name abgebrochen."
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Auswahl für virtuelle Umgebung: $choice"
        return 1
    fi
    return 0
}

# Installierte Pakete in einer virtuellen Umgebung anzeigen
list_venv_packages() {
    init_venv_dir || return 1
    local venvs=("$VENV_DIR"/*)
    if [ ${#venvs[@]} -eq 0 ] || [ "${venvs[0]}" = "$VENV_DIR/*" ]; then
        echo -e "${YELLOW}⚠️ Keine virtuellen Umgebungen gefunden in $VENV_DIR${NC}"
        log_message "WARNING" "Keine virtuellen Umgebungen gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare virtuelle Umgebungen:${NC}"
    local i=1
    for venv in "${venvs[@]}"; do
        echo -e " ${GREEN}[$i]${NC} $(basename "$venv")"
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer der Umgebung für Paketliste (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#venvs[@]} ]; then
        local venv_path="${venvs[$index]}"
        local venv_name=$(basename "$venv_path")
        echo -e "${CYAN}📦 Installierte Pakete in '$venv_name':${NC}"
        if "$venv_path/bin/pip" list --format=columns | tail -n +3; then
            log_message "INFO" "Paketliste für virtuelle Umgebung $venv_name angezeigt."
        else
            echo -e "${YELLOW}⚠️ Keine Pakete installiert oder Fehler beim Abrufen der Liste.${NC}"
            log_message "WARNING" "Fehler beim Abrufen der Paketliste für $venv_name."
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Auswahl für virtuelle Umgebung: $choice"
        return 1
    fi
    return 0
}

# Hauptmenü
run_python_env_manager() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🐍 Python-Umgebungs-Manager      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Python-Befehl aus Konfigurationsdatei laden, falls verfügbar
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$PYTHON_CMD" ] && PYTHON_CMD="$PYTHON_CMD"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Neue virtuelle Umgebung erstellen"
        echo -e " ${GREEN}2)${NC} Virtuelle Umgebung aktivieren"
        echo -e " ${GREEN}3)${NC} Virtuelle Umgebung löschen"
        echo -e " ${GREEN}4)${NC} Installierte Pakete anzeigen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                create_venv
                echo ""
                ;;
            2)
                activate_venv
                echo ""
                ;;
            3)
                delete_venv
                echo ""
                ;;
            4)
                list_venv_packages
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Python-Umgebungs-Manager beendet.${NC}"
                log_message "INFO" "Python-Umgebungs-Manager beendet."
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
log_message "INFO" "Plugin python_env_manager.sh (v$PLUGIN_VERSION) geladen."
