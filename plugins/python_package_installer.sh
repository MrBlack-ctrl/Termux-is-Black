#!/bin/bash

# Plugin für Termux-is-Black: Python-Paket-Installer
# Datei: plugins/python_package_installer.sh
# Beschreibung: Installiert, aktualisiert, deinstalliert Python-Pakete und verwaltet den pip-Cache
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
    echo "[$timestamp] [$level] [python_package_installer] $message" >> "$log_file"
}

# Python-Befehl (aus ~/.termux_startup.conf oder Standard)
PYTHON_CMD="python3"
CONFIG_FILE="$HOME/.termux_startup.conf"

# Paket installieren
install_package() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    read -p "$(echo -e "${BLUE}Paketname (z.B. requests==2.28.1 oder leer für Eingabe abbrechen): ${NC}")" package
    if [ -z "$package" ]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    echo -e "${CYAN}📦 Installiere Paket '$package'...${NC}"
    if "$PYTHON_CMD" -m pip install "$package"; then
        echo -e "${GREEN}${BOLD}✅ Paket '$package' erfolgreich installiert.${NC}"
        log_message "INFO" "Paket $package installiert."
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Installieren des Pakets '$package'.${NC}"
        log_message "ERROR" "Fehler beim Installieren des Pakets: $package"
        return 1
    fi
    return 0
}

# Paket aktualisieren
update_package() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    echo -e "${CYAN}📦 Liste installierte Pakete...${NC}"
    local packages=$("$PYTHON_CMD" -m pip list --format=columns | tail -n +3 | awk '{print $1}')
    if [ -z "$packages" ]; then
        echo -e "${YELLOW}⚠️ Keine Pakete installiert.${NC}"
        log_message "WARNING" "Keine Pakete installiert."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Installierte Pakete:${NC}"
    local i=1
    local pkg_array=()
    echo "$packages" | while read -r pkg; do
        echo -e " ${GREEN}[$i]${NC} $pkg"
        pkg_array+=("$pkg")
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer des zu aktualisierenden Pakets (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#pkg_array[@]} ]; then
        local package="${pkg_array[$index]}"
        echo -e "${CYAN}📦 Aktualisiere Paket '$package'...${NC}"
        if "$PYTHON_CMD" -m pip install --upgrade "$package"; then
            echo -e "${GREEN}${BOLD}✅ Paket '$package' erfolgreich aktualisiert.${NC}"
            log_message "INFO" "Paket $package aktualisiert."
        else
            echo -e "${RED}${BOLD}❌ Fehler beim Aktualisieren des Pakets '$package'.${NC}"
            log_message "ERROR" "Fehler beim Aktualisieren des Pakets: $package"
            return 1
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Paketauswahl: $choice"
        return 1
    fi
    return 0
}

# Paket deinstallieren
uninstall_package() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    echo -e "${CYAN}📦 Liste installierte Pakete...${NC}"
    local packages=$("$PYTHON_CMD" -m pip list --format=columns | tail -n +3 | awk '{print $1}')
    if [ -z "$packages" ]; then
        echo -e "${YELLOW}⚠️ Keine Pakete installiert.${NC}"
        log_message "WARNING" "Keine Pakete installiert."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Installierte Pakete:${NC}"
    local i=1
    local pkg_array=()
    echo "$packages" | while read -r pkg; do
        echo -e " ${GREEN}[$i]${NC} $pkg"
        pkg_array+=("$pkg")
        ((i++))
    done
    read -p "$(echo -e "${BLUE}Nummer des zu deinstallierenden Pakets (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#pkg_array[@]} ]; then
        local package="${pkg_array[$index]}"
        read -p "$(echo -e "${YELLOW}⚠️ Warnung: '$package' wird deinstalliert! Fortfahren? (j/N): ${NC}")" confirm
        if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
            if "$PYTHON_CMD" -m pip uninstall -y "$package"; then
                echo -e "${GREEN}${BOLD}✅ Paket '$package' erfolgreich deinstalliert.${NC}"
                log_message "INFO" "Paket $package deinstalliert."
            else
                echo -e "${RED}${BOLD}❌ Fehler beim Deinstallieren des Pakets '$package'.${NC}"
                log_message "ERROR" "Fehler beim Deinstallieren des Pakets: $package"
                return 1
            fi
        else
            echo -e "${CYAN}Abgebrochen.${NC}"
            log_message "INFO" "Deinstallation von $package abgebrochen."
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Paketauswahl: $choice"
        return 1
    fi
    return 0
}

# pip-Cache bereinigen
clean_pip_cache() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    echo -e "${CYAN}🧹 Bereinige pip-Cache...${NC}"
    if "$PYTHON_CMD" -m pip cache purge; then
        echo -e "${GREEN}${BOLD}✅ pip-Cache erfolgreich bereinigt.${NC}"
        log_message "INFO" "pip-Cache bereinigt."
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Bereinigen des pip-Cache.${NC}"
        log_message "ERROR" "Fehler beim Bereinigen des pip-Cache."
        return 1
    fi
    return 0
}

# Verfügbare Updates prüfen
check_package_updates() {
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Python nicht installiert (pkg install python)${NC}"
        log_message "WARNING" "Python nicht verfügbar."
        return 1
    fi

    echo -e "${CYAN}🔍 Prüfe verfügbare Paket-Updates...${NC}"
    local outdated=$("$PYTHON_CMD" -m pip list --outdated --format=columns | tail -n +3)
    if [ -z "$outdated" ]; then
        echo -e "${GREEN}${BOLD}✅ Alle Pakete sind auf dem neuesten Stand.${NC}"
        log_message "INFO" "Keine Paket-Updates verfügbar."
        return 0
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Veraltete Pakete:${NC}"
    echo "$outdated" | while read -r line; do
        echo -e " ${YELLOW}📦 $line${NC}"
    done
    read -p "$(echo -e "${BLUE}Alle veralteten Pakete aktualisieren? (j/N): ${NC}")" confirm
    if [[ "$confirm" =~ ^[jJ](a)?$ ]]; then
        echo "$outdated" | awk '{print $1}' | while read -r package; do
            echo -e "${CYAN}📦 Aktualisiere Paket '$package'...${NC}"
            if "$PYTHON_CMD" -m pip install --upgrade "$package"; then
                echo -e "${GREEN}${BOLD}✅ Paket '$package' aktualisiert.${NC}"
                log_message "INFO" "Paket $package aktualisiert."
            else
                echo -e "${RED}${BOLD}❌ Fehler beim Aktualisieren des Pakets '$package'.${NC}"
                log_message "ERROR" "Fehler beim Aktualisieren des Pakets: $package"
            fi
        done
    else
        echo -e "${CYAN}Abgebrochen.${NC}"
        log_message "INFO" "Aktualisierung veralteter Pakete abgebrochen."
    fi
    return 0
}

# Hauptmenü
run_python_package_installer() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      📦 Python-Paket-Installer      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Python-Befehl aus Konfigurationsdatei laden
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$PYTHON_CMD" ] && PYTHON_CMD="$PYTHON_CMD"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Paket installieren"
        echo -e " ${GREEN}2)${NC} Paket aktualisieren"
        echo -e " ${GREEN}3)${NC} Paket deinstallieren"
        echo -e " ${GREEN}4)${NC} pip-Cache bereinigen"
        echo -e " ${GREEN}5)${NC} Verfügbare Updates prüfen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                install_package
                echo ""
                ;;
            2)
                update_package
                echo ""
                ;;
            3)
                uninstall_package
                echo ""
                ;;
            4)
                clean_pip_cache
                echo ""
                ;;
            5)
                check_package_updates
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Python-Paket-Installer beendet.${NC}"
                log_message "INFO" "Python-Paket-Installer beendet."
                break
                ;;
            *)
                echo -e "${RED}${BOLD}❌ Ungültige Option. Bitte wähle 1-5 oder q.${NC}"
                log_message "WARNING" "Ungültige Option ausgewählt: $choice"
                echo ""
                ;;
        esac
    done
}

# Plugin-Version (für spätere Erweiterungen)
PLUGIN_VERSION="1.0.0"

# Logging beim Laden des Plugins
log_message "INFO" "Plugin python_package_installer.sh (v$PLUGIN_VERSION) geladen."
