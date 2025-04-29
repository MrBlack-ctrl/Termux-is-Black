#!/bin/bash

# Plugin für Termux-is-Black: Git-Automatisierer
# Datei: plugins/git_automator.sh
# Beschreibung: Automatisiert Git-Workflows (Commits, Pushes, Pulls, Statusprüfungen) für Projekte
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
    echo "[$timestamp] [$level] [git_automator] $message" >> "$log_file"
}

# Standard-Verzeichnis für Projekte
PROJECT_DIR="$HOME/storage/shared/projects"
CONFIG_FILE="$HOME/.termux_startup.conf"

# Git-Repositories finden
list_repos() {
    local repos=$(find "$PROJECT_DIR" -type d -name ".git" -exec dirname {} \; 2>/dev/null)
    if [ -z "$repos" ]; then
        echo -e "${YELLOW}⚠️ Keine Git-Repositories gefunden in $PROJECT_DIR${NC}"
        log_message "WARNING" "Keine Git-Repositories in $PROJECT_DIR gefunden."
        return 1
    fi

    echo -e "${YELLOW}${BOLD}${UNDERLINE}Gefundene Git-Repositories:${NC}"
    local i=1
    local repo_array=()
    echo "$repos" | while read -r repo; do
        echo -e " ${GREEN}[$i]${NC} $repo"
        repo_array+=("$repo")
        ((i++))
    done
    echo "$repos" > /tmp/git_repos_list
    return 0
}

# Git-Status prüfen
check_git_status() {
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}⚠️ git nicht installiert (pkg install git)${NC}"
        log_message "WARNING" "git nicht verfügbar."
        return 1
    fi

    list_repos || return 1
    local repos=($(cat /tmp/git_repos_list))
    read -p "$(echo -e "${BLUE}Nummer des Repositories (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        rm -f /tmp/git_repos_list
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#repos[@]} ]; then
        local repo_path="${repos[$index]}"
        echo -e "${CYAN}📂 Prüfe Status von '$repo_path'...${NC}"
        cd "$repo_path" || return 1
        if git status; then
            echo -e "${GREEN}${BOLD}✅ Statusprüfung abgeschlossen.${NC}"
            log_message "INFO" "Git-Status für $repo_path geprüft."
        else
            echo -e "${RED}${BOLD}❌ Fehler beim Prüfen des Status.${NC}"
            log_message "ERROR" "Fehler beim Prüfen des Status für $repo_path."
            return 1
        fi
        cd - >/dev/null
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Repository-Auswahl: $choice"
        return 1
    fi
    rm -f /tmp/git_repos_list
    return 0
}

# Git-Commit und Push
commit_and_push() {
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}⚠️ git nicht installiert (pkg install git)${NC}"
        log_message "WARNING" "git nicht verfügbar."
        return 1
    fi

    list_repos || return 1
    local repos=($(cat /tmp/git_repos_list))
    read -p "$(echo -e "${BLUE}Nummer des Repositories (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        rm -f /tmp/git_repos_list
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#repos[@]} ]; then
        local repo_path="${repos[$index]}"
        read -p "$(echo -e "${BLUE}Commit-Nachricht eingeben: ${NC}")" commit_message
        if [ -z "$commit_message" ]; then
            echo -e "${RED}${BOLD}❌ Ungültige Commit-Nachricht.${NC}"
            log_message "ERROR" "Keine Commit-Nachricht angegeben."
            return 1
        fi

        echo -e "${CYAN}📂 Führe Commit und Push in '$repo_path' aus...${NC}"
        cd "$repo_path" || return 1
        if git add . && git commit -m "$commit_message" && git push origin HEAD; then
            echo -e "${GREEN}${BOLD}✅ Commit und Push erfolgreich.${NC}"
            log_message "INFO" "Commit und Push für $repo_path erfolgreich."
        else
            echo -e "${RED}${BOLD}❌ Fehler beim Commit oder Push.${NC}"
            log_message "ERROR" "Fehler beim Commit oder Push für $repo_path."
            return 1
        fi
        cd - >/dev/null
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Repository-Auswahl: $choice"
        return 1
    fi
    rm -f /tmp/git_repos_list
    return 0
}

# Git-Pull
pull_updates() {
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}⚠️ git nicht installiert (pkg install git)${NC}"
        log_message "WARNING" "git nicht verfügbar."
        return 1
    fi

    list_repos || return 1
    local repos=($(cat /tmp/git_repos_list))
    read -p "$(echo -e "${BLUE}Nummer des Repositories (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        rm -f /tmp/git_repos_list
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#repos[@]} ]; then
        local repo_path="${repos[$index]}"
        echo -e "${CYAN}📂 Führe Pull in '$repo_path' aus...${NC}"
        cd "$repo_path" || return 1
        if git pull origin HEAD; then
            echo -e "${GREEN}${BOLD}✅ Pull erfolgreich.${NC}"
            log_message "INFO" "Pull für $repo_path erfolgreich."
        else
            echo -e "${RED}${BOLD}❌ Fehler beim Pull.${NC}"
            log_message "ERROR" "Fehler beim Pull für $repo_path."
            return 1
        fi
        cd - >/dev/null
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Repository-Auswahl: $choice"
        return 1
    fi
    rm -f /tmp/git_repos_list
    return 0
}

# Hauptmenü
run_git_automator() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      📂 Git-Automatisierer      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    # Projekt-Verzeichnis aus Konfigurationsdatei laden
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        [ -n "$PROJECT_DIR" ] && PROJECT_DIR="$PROJECT_DIR"
    fi

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Git-Status prüfen"
        echo -e " ${GREEN}2)${NC} Commit und Push"
        echo -e " ${GREEN}3)${NC} Updates pullen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                check_git_status
                echo ""
                ;;
            2)
                commit_and_push
                echo ""
                ;;
            3)
                pull_updates
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Git-Automatisierer beendet.${NC}"
                log_message "INFO" "Git-Automatisierer beendet."
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
log_message "INFO" "Plugin git_automator.sh (v$PLUGIN_VERSION) geladen."
