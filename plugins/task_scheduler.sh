#!/bin/bash

# Plugin für Termux-is-Black: Aufgabenplaner
# Datei: plugins/task_scheduler.sh
# Beschreibung: Plant, verwaltet und führt automatisierte Aufgaben in Termux mit termux-job-scheduler
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
    echo "[$timestamp] [$level] [task_scheduler] $message" >> "$log_file"
}

# Verzeichnis für Aufgaben-Skripte
TASK_DIR="$HOME/.termux_is_black_tasks"
# Log-Datei für ausgeführte Aufgaben
TASK_LOG="$HOME/task_scheduler.log"

# Aufgabenverzeichnis initialisieren
init_task_dir() {
    if [ ! -d "$TASK_DIR" ]; then
        mkdir -p "$TASK_DIR"
        if [ $? -eq 0 ]; then
            log_message "INFO" "Aufgabenverzeichnis $TASK_DIR erstellt."
        else
            log_message "ERROR" "Konnte Aufgabenverzeichnis $TASK_DIR nicht erstellen."
            echo -e "${RED}${BOLD}❌ Fehler: Konnte $TASK_DIR nicht erstellen.${NC}"
            return 1
        fi
    fi
    return 0
}

# Neue Aufgabe planen
schedule_task() {
    if ! command -v termux-job-scheduler &> /dev/null; then
        echo -e "${YELLOW}⚠️ termux-job-scheduler nicht installiert (pkg install termux-api)${NC}"
        log_message "WARNING" "termux-job-scheduler nicht verfügbar."
        return 1
    fi

    init_task_dir || return 1
    read -p "$(echo -e "${BLUE}Aufgabenname (z.B. daily_backup): ${NC}")" task_name
    if [ -z "$task_name" ]; then
        echo -e "${RED}${BOLD}❌ Ungültiger Aufgabenname.${NC}"
        log_message "ERROR" "Kein Aufgabenname angegeben."
        return 1
    fi

    read -p "$(echo -e "${BLUE}Befehl oder Skriptpfad (z.B. 'pkg update' oder '~/script.sh'): ${NC}")" task_cmd
    if [ -z "$task_cmd" ]; then
        echo -e "${RED}${BOLD}❌ Ungültiger Befehl.${NC}"
        log_message "ERROR" "Kein Befehl angegeben."
        return 1
    fi

    read -p "$(echo -e "${BLUE}Intervall in Minuten (z.B. 1440 für täglich, 60 für stündlich): ${NC}")" interval
    if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ]; then
        echo -e "${RED}${BOLD}❌ Ungültiges Intervall (muss eine positive Zahl sein).${NC}"
        log_message "ERROR" "Ungültiges Intervall: $interval"
        return 1
    fi

    # Skript für die Aufgabe erstellen
    local task_script="$TASK_DIR/$task_name.sh"
    cat > "$task_script" << EOF
#!/bin/bash
# Aufgabe: $task_name
# Erstellt: $(date '+%Y-%m-%d %H:%M:%S')
$task_cmd >> $TASK_LOG 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aufgabe $task_name ausgeführt" >> $TASK_LOG
EOF
    chmod +x "$task_script"

    # Aufgabe mit termux-job-scheduler planen
    termux-job-scheduler -s "$task_script" --period-ms $((interval * 60000)) >/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✅ Aufgabe '$task_name' geplant (Intervall: $interval Minuten).${NC}"
        log_message "INFO" "Aufgabe $task_name geplant mit Intervall $interval Minuten."
    else
        echo -e "${RED}${BOLD}❌ Fehler beim Planen der Aufgabe.${NC}"
        log_message "ERROR" "Fehler beim Planen der Aufgabe: $task_name"
        rm -f "$task_script"
        return 1
    fi
    return 0
}

# Geplante Aufgaben auflisten
list_tasks() {
    init_task_dir || return 1
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Geplante Aufgaben:${NC}"
    if ls "$TASK_DIR"/*.sh >/dev/null 2>&1; then
        local i=1
        for task_script in "$TASK_DIR"/*.sh; do
            local task_name=$(basename "$task_script" .sh)
            local task_cmd=$(grep -v '^#' "$task_script" | grep -v 'echo.*TASK_LOG' | tail -n 1)
            echo -e " ${GREEN}[$i]${NC} $task_name (${BLUE}Befehl: $task_cmd${NC})"
            ((i++))
        done
    else
        echo -e " ${YELLOW}⚠️ Keine geplanten Aufgaben gefunden in $TASK_DIR${NC}"
        log_message "WARNING" "Keine Aufgaben in $TASK_DIR gefunden."
    fi
}

# Aufgabe löschen
delete_task() {
    init_task_dir || return 1
    local tasks=("$TASK_DIR"/*.sh)
    if [ ${#tasks[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Keine Aufgaben zum Löschen gefunden.${NC}"
        log_message "WARNING" "Keine Aufgaben zum Löschen gefunden."
        return 1
    fi

    list_tasks
    read -p "$(echo -e "${BLUE}Nummer der zu löschenden Aufgabe (oder 'q' zum Abbrechen): ${NC}")" choice
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${CYAN}Abgebrochen.${NC}"
        return 0
    fi

    local index=$((choice - 1))
    if [ "$index" -ge 0 ] && [ "$index" -lt ${#tasks[@]} ]; then
        local task_script="${tasks[$index]}"
        local task_name=$(basename "$task_script" .sh)
        echo -e "${CYAN}Lösche Aufgabe $task_name...${NC}"
        if termux-job-scheduler -s "$task_script" --cancel >/dev/null && rm -f "$task_script"; then
            echo -e "${GREEN}${BOLD}✅ Aufgabe $task_name gelöscht.${NC}"
            log_message "INFO" "Aufgabe $task_name gelöscht."
        else
            echo -e "${RED}${BOLD}❌ Fehler beim Löschen der Aufgabe.${NC}"
            log_message "ERROR" "Fehler beim Löschen der Aufgabe: $task_name"
            return 1
        fi
    else
        echo -e "${RED}${BOLD}❌ Ungültige Auswahl.${NC}"
        log_message "ERROR" "Ungültige Aufgaben-Auswahl: $choice"
        return 1
    fi
    return 0
}

# Aufgaben-Log anzeigen
view_task_log() {
    if [ -f "$TASK_LOG" ]; then
        echo -e "${YELLOW}${BOLD}${UNDERLINE}Aufgaben-Log:${NC}"
        cat "$TASK_LOG" | while read -r line; do
            echo -e " ${GREEN}📜 $line${NC}"
        done
    else
        echo -e " ${YELLOW}⚠️ Kein Aufgaben-Log gefunden in $TASK_LOG${NC}"
        log_message "WARNING" "Kein Aufgaben-Log gefunden."
    fi
}

# Hauptmenü
run_task_scheduler() {
    clear
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      ⏰ Aufgabenplaner      ${NC}"
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo ""

    while true; do
        echo -e "${YELLOW}${BOLD}Optionen:${NC}"
        echo -e " ${GREEN}1)${NC} Neue Aufgabe planen"
        echo -e " ${GREEN}2)${NC} Geplante Aufgaben auflisten"
        echo -e " ${GREEN}3)${NC} Aufgabe löschen"
        echo -e " ${GREEN}4)${NC} Aufgaben-Log anzeigen"
        echo -e " ${GREEN}q)${NC} Beenden"
        echo ""
        read -p "$(echo -e "${BLUE}Wähle eine Option: ${NC}")" choice

        case "$choice" in
            1)
                schedule_task
                echo ""
                ;;
            2)
                list_tasks
                echo ""
                ;;
            3)
                delete_task
                echo ""
                ;;
            4)
                view_task_log
                echo ""
                ;;
            q|Q)
                echo -e "${GREEN}${BOLD}✅ Aufgabenplaner beendet.${NC}"
                log_message "INFO" "Aufgabenplaner beendet."
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
log_message "INFO" "Plugin task_scheduler.sh (v$PLUGIN_VERSION) geladen."