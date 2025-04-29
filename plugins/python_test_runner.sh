#!/bin/bash

# Plugin für Termux-is-Black: Python-Test-Runner
# Datei: plugins/python_test_runner.sh
# Beschreibung: Führt automatisierte Tests für Python-Projekte mit unittest, pytest oder nose aus
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
    echo "[$timestamp] [$level] [python_test_runner] $message" >> "$log_file"
}

# Standard-Verzeichnis für Python-Projekte
TEST_DIR="$HOME/storage/shared/py"
# Python-Befehl (aus ~/.termux_startup.conf oder Standard)
PYTHON_CMD="python3"
CONFIG_FILE="$HOME/.termux_startup.conf"
# Log-Datei für Testergebnisse
TEST_LOG="$HOME/test_runner.log"

# Test-Framework auswählen und Tests ausführen
run_tests() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    local test_files=$(find "$TEST_DIR" -type f -name "test_*.py" 2>/dev/null)
    if [ -z "$test_files" ]; then
        echo -e "${YELLOW}⚠️ Keine Testdateien gefunden in $TEST_DIR${NC}"
        log_message "WARNING" "Keine Testdateien in $TEST_DIR gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Verfügbare Test-Frameworks:${NC}"
    echo -e " ${GREEN}1)${NC} unittest"
    if command -v pytest &> /dev/null; then
        echo -e " ${GREEN}2)${NC} pytest"
    fi
    if command -v nosetests &> /dev/null; then
        echo -e " ${GREEN}3)${NC} nose"
    fi
    echo -e " ${GREEN}q)${NC} Abbrechen"
    read -p "$(echo -e "${BLUE}Wähle ein Test-Framework: ${NC}")" framework_choice

    case "$framework_choice" in
        1)
            local framework="unittest"
            local test_cmd="$PYTHON_CMD -m unittest"
            ;;
        2)
            if command -v pytest &> /dev/null; then
                local framework="pytest"
                local test_cmd="pytest"
            else
                echo -e "${RED}${BOLD}❌ pytest nicht installiert (pip install pytest)${NC}"
                log_message "ERROR" "pytest nicht verfügbar."
                return 1
            fi
            ;;
        3)
            if command -v nosetests &> /dev/null; then
                local framework="nose"
                local test_cmd="nosetests"
            else
                echo -e "${RED}${BOLD}❌ nose nicht installiert (pip install nose)${NC}"
                log_message "ERROR" "nose nicht verfügbar."
                return 1
            fi
            ;;
        q|Q)
            echo -e "${CYAN}Abgebrochen.${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
            log_message "ERROR" "Ungültige Framework-Auswahl: $framework_choice"
            return 1
            ;;
    esac

    echo -e "${CYAN}🧪 Führe Tests mit $framework aus...${NC}"
    local test_output
    if test_output=$($test_cmd "$TEST_DIR" 2>&1 >> "$TEST_LOG"); then
        echo -e "${GREEN}${BOLD}✅ Tests erfolgreich ausgeführt. Ergebnisse in $TEST_LOG gespeichert.${NC}"
        echo "$test_output" | while read -r line; do
            echo -e " ${GREEN}📜 $line${NC}"
        done
        log_message "INFO" "Tests mit $framework erfolgreich ausgeführt."
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Ausführen der Tests:${NC}"
        echo "$test_output" | while read -r line; do
            echo -e " ${RED}⚠️ $line${NC}"
        done
        log_message "ERROR" "Fehler beim Ausführen der Tests mit $framework."
        return 1
    fi
    return 0
}

# Code-Abdeckung prüfen
check_coverage() {
    if ! command -v coverage &> /dev/null; then
        echo -e "${YELLOW}⚠️ coverage nicht installiert (pip install coverage)${NC}"
        log_message "WARNING" "coverage nicht verfügbar."
        return 1
    fi

    echo -e "${CYAN}🧪 Prüfe Code-Abdeckung in $TEST_DIR...${NC}"
    if coverage run -m pytest "$TEST_DIR" 2>/dev/null && coverage report; then
        echo -e "${GREEN}${BOLD}✅ Code-Abdeckungsbericht erstellt:${NC}"
        coverage report | while read -r line; do
            echo -e " ${GREEN}📊 $line${NC}"
        done
        log_message "INFO" "Code-Abdeckungsbericht erstellt."
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Erstellen des Abdeckungsberichts.${NC}"
        log_message "ERROR" "Fehler beim Erstellen des Abdeckungsberichts."
        return 1
    fi
    return 0
}

# Test-Log anzeigen
view_test_log() {
    if [ -f "$TEST_LOG" ]; then
        echo -e "${YELLOW}${BOLD}${UNDERLINE}Test-Log:${NC}"
        cat "$TEST_LOG" | while read -r line; do
            echo -e " ${GREEN}📜 $line${NC}"
        done
        log_message "INFO" "Test-Log angezeigt."
    else
        echo -e "${YELLOW}⚠️ Kein Test-Log gefunden in $TEST_LOG${NC}"
        log_message "WARNING" "Kein Test-Log gefunden."
    fi
}

# Hauptmenü
run_python_test_runner() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🧪 Python-Test-Runner      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Test-Verzeichnis und Python-Befehl aus Konfigurationsdatei laden
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$TEST_DIR" ] && TEST_DIR="$TEST_DIR"
        [ -n "$PYTHON_CMD" ] && PYTHON_CMD="$PYTHON_CMD"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Tests ausführen"
        echo -e " ${GREEN}2)${NC} Code-Abdeckung prüfen"
        echo -e " ${GREEN}3)${NC} Test-Log anzeigen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                run_tests
                echo ""
                ;;
            2)
                check_coverage
                echo ""
                ;;
            3)
                view_test_log
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Python-Test-Runner beendet.${NC}"
                log_message "INFO" "Python-Test-Runner beendet."
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
log_message "INFO" "Plugin python_test_runner.sh (v$PLUGIN_VERSION) geladen."
