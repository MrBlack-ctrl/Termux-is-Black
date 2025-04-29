#!/bin/bash

# Plugin für Termux-is-Black: Python-Skript-Analyzer
# Datei: plugins/python_script_analyzer.sh
# Beschreibung: Analysiert Python-Skripte auf Syntaxfehler, PEP 8-Stilverletzungen und Sicherheitsrisiken
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
    echo "[$timestamp] [$level] [python_script_analyzer] $message" >> "$log_file"
}

# Standard-Verzeichnis für Python-Skripte
PYTHON_SCRIPT_DIR="$HOME/storage/shared/py"
# Python-Befehl (aus ~/.termux_startup.conf oder Standard)
PYTHON_CMD="python3"
CONFIG_FILE="$HOME/.termux_startup.conf"

# Syntaxprüfung
check_syntax() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    local scripts=("$PYTHON_SCRIPT_DIR"/*.py)
    if [ ${#scripts[@]} -eq 0 ] || [ "${scripts[0]}" = "$PYTHON_SCRIPT_DIR/*.py" ]; then
        echo -e "${YELLOW}⚠️ Keine Python-Skripte gefunden in $PYTHON_SCRIPT_DIR${NC}"
        log_message "WARNING" "Keine Python-Skripte in $PYTHON_SCRIPT_DIR gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare Python-Skripte:${NC}"
    local i=1
    for script in "${scripts[@]}"; do
        echo -e " ${GREEN}[$i]${NC} $(basename "$script")"
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer des zu prüfenden Skripts (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#scripts[@]} ]; then
        local script_path="${scripts[$index]}"
        echo -e "${CYAN}🔍 Prüfe Syntax von '$script_path'...${NC}"
        if "$PYTHON_CMD" -m py_compile "$script_path" 2>/dev/null; then
            echo -e "${GREEN}${BOLD}✅ Syntaxprüfung erfolgreich: Keine Fehler gefunden.${NC}"
            log_message "INFO" "Syntaxprüfung erfolgreich für $script_path."
        else
            echo -e "${RED}${BOLD}❌ Syntaxfehler gefunden:${NC}"
            "$PYTHON_CMD" -m py_compile "$script_path" 2>&1 | while read -r line; do
                echo -e " ${RED}⚠️ $line${NC}"
            done
            log_message "ERROR" "Syntaxfehler in $script_path gefunden."
            return 1
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Skriptauswahl: $choice"
        return 1
    fi
    return 0
}

# PEP 8-Stilprüfung
check_pep8() {
    if ! command -v flake8 &> /dev/null; then
        echo -e "${YELLOW}⚠️ flake8 nicht installiert (pip install flake8)${NC}"
        log_message "WARNING" "flake8 nicht verfügbar."
        return 1
    fi

    local scripts=("$PYTHON_SCRIPT_DIR"/*.py)
    if [ ${#scripts[@]} -eq 0 ] || [ "${scripts[0]}" = "$PYTHON_SCRIPT_DIR/*.py" ]; then
        echo -e "${YELLOW}⚠️ Keine Python-Skripte gefunden in $PYTHON_SCRIPT_DIR${NC}"
        log_message "WARNING" "Keine Python-Skripte in $PYTHON_SCRIPT_DIR gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare Python-Skripte:${NC}"
    local i=1
    for script in "${scripts[@]}"; do
        echo -e " ${GREEN}[$i]${NC} $(basename "$script")"
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer des zu prüfenden Skripts (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#scripts[@]} ]; then
        local script_path="${scripts[$index]}"
        echo -e "${CYAN}🔍 Prüfe PEP 8-Stil von '$script_path'...${NC}"
        if flake8 "$script_path" --max-line-length=120; then
            echo -e "${GREEN}${BOLD}✅ PEP 8-Prüfung erfolgreich: Keine Stilverletzungen gefunden.${NC}"
            log_message "INFO" "PEP 8-Prüfung erfolgreich für $script_path."
        else
            echo -e "${YELLOW}⚠️ Stilverletzungen gefunden:${NC}"
            flake8 "$script_path" --max-line-length=120 | while read -r line; do
                echo -e " ${YELLOW}⚠️ $line${NC}"
            done
            log_message "WARNING" "PEP 8-Stilverletzungen in $script_path gefunden."
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Skriptauswahl: $choice"
        return 1
    fi
    return 0
}

# Sicherheitsprüfung
check_security() {
    local scripts=("$PYTHON_SCRIPT_DIR"/*.py)
    if [ ${#scripts[@]} -eq 0 ] || [ "${scripts[0]}" = "$PYTHON_SCRIPT_DIR/*.py" ]; then
        echo -e "${YELLOW}⚠️ Keine Python-Skripte gefunden in $PYTHON_SCRIPT_DIR${NC}"
        log_message "WARNING" "Keine Python-Skripte in $PYTHON_SCRIPT_DIR gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare Python-Skripte:${NC}"
    local i=1
    for script in "${scripts[@]}"; do
        echo -e " ${GREEN}[$i]${NC} $(basename "$script")"
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer des zu prüfenden Skripts (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#scripts[@]} ]; then
        local script_path="${scripts[$index]}"
        echo -e "${CYAN}🔍 Prüfe Sicherheitsrisiken in '$script_path'...${NC}"
        local issues=0
        # Prüfe auf unsichere Imports und Funktionen
        if grep -E -n 'os\.system|subprocess\.|eval\(|exec\(' "$script_path" 2>/dev/null; then
            echo -e "${RED}${BOLD}⚠️ Potenzielle Sicherheitsrisiken gefunden:${NC}"
            grep -E -n 'os\.system|subprocess\.|eval\(|exec\(' "$script_path" | while read -r line; do
                echo -e " ${RED}⚠️ $line${NC}"
            done
            ((issues++))
            log_message "WARNING" "Sicherheitsrisiken in $script_path gefunden."
        fi
        if [ $issues -eq 0 ]; then
            echo -e "${GREEN}${BOLD}✅ Sicherheitsprüfung erfolgreich: Keine Risiken gefunden.${NC}"
            log_message "INFO" "Sicherheitsprüfung erfolgreich für $script_path."
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Skriptauswahl: $choice"
        return 1
    fi
    return 0
}

# Hauptmenü
run_python_script_analyzer() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🔍 Python-Skript-Analyzer      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Python-Skript-Verzeichnis und Befehl aus Konfigurationsdatei laden
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$PYTHON_SCRIPT_DIR" ] && PYTHON_SCRIPT_DIR="$PYTHON_SCRIPT_DIR"
        [ -n "$PYTHON_CMD" ] && PYTHON_CMD="$PYTHON_CMD"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Syntaxprüfung"
        echo -e " ${GREEN}2)${NC} PEP 8-Stilprüfung"
        echo -e " ${GREEN}3)${NC} Sicherheitsprüfung"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                check_syntax
                echo ""
                ;;
            2)
                check_pep8
                echo ""
                ;;
            3)
                check_security
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Python-Skript-Analyzer beendet.${NC}"
                log_message "INFO" "Python-Skript-Analyzer beendet."
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
log_message "INFO" "Plugin python_script_analyzer.sh (v$PLUGIN_VERSION) geladen."
