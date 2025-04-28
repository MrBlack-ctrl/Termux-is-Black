#!/bin/bash

# --- Konfiguration ---
CONFIG_FILE="$HOME/.termux_startup.conf"
LOG_FILE="$HOME/termux_startup.log"
REPO_URL="https://github.com/MrBlack-ctrl/Termux-is-Black"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/startup.sh"
PLUGIN_DIR="$HOME/Termux-is-Black/plugins"
PLUGIN_REPO_URL="https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/plugins/"

# Standardkonfiguration laden oder erstellen
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo -e "${YELLOW}Konfigurationsdatei nicht gefunden. Erstelle Standardkonfiguration...${NC}"
        cat << EOF > "$CONFIG_FILE"
# Termux Startup Konfiguration
SCRIPT_NAME="startup.sh"
PYTHON_SCRIPT_DIR="$HOME/storage/shared/py"
PYTHON_CMD="python3"
BASHRC_FILE="$HOME/.bashrc"
AUTOSTART_MARKER="# AUTOSTART_TERMUX_SCRIPT_V1"
LOG_FILE="$HOME/termux_startup.log"
THEME="default"
PLUGIN_DIR="$HOME/Termux-is-Black/plugins"
PLUGIN_REPO_URL="$PLUGIN_REPO_URL"
EOF
        source "$CONFIG_FILE"
        log_message "INFO" "Standardkonfiguration '$CONFIG_FILE' erstellt."
    fi
    SCRIPT_PATH="$HOME/$SCRIPT_NAME"
}

# --- Farben und Stil (Theme-fähig) ---
load_theme() {
    THEME=${THEME:-"default"}
    case $THEME in
        dark)
            RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
            BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
            WHITE='\033[0;37m'; BOLD='\033[1m'; UNDERLINE='\033[4m'; NC='\033[0m'
            ;;
        mib)
            RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
            BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
            WHITE='\033[1;37m'; BOLD='\033[1m'; UNDERLINE='\033[4m'; NC='\033[0m'
            ;;
        light)
            RED='\033[0;91m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'
            BLUE='\033[0;94m'; MAGENTA='\033[0;95m'; CYAN='\033[0;96m'
            WHITE='\033[0;97m'; BOLD='\033[1m'; UNDERLINE='\033[4m'; NC='\033[0m'
            ;;
        *)
            RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
            BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
            WHITE='\033[0;37m'; BOLD='\033[1m'; UNDERLINE='\033[4m'; NC='\033[0m'
            ;;
    esac
}

# --- Logging ---
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo -e "${level}: $message"
}

# --- Fortschrittsanzeige ---
run_with_progress() {
    local cmd="$1"
    echo -e "${CYAN}Führe aus: $cmd...${NC}"
    $cmd 2>> "$LOG_FILE" &
    local pid=$!
    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 1
    done
    echo ""
    wait $pid
    if [ $? -eq 0 ]; then
        log_message "INFO" "Befehl '$cmd' erfolgreich abgeschlossen."
        echo -e "${GREEN}Erfolgreich abgeschlossen.${NC}"
    else
        log_message "ERROR" "Fehler bei der Ausführung von '$cmd'."
        echo -e "${RED}Fehler bei der Ausführung.${NC}"
    fi
}

# --- Sicherheitsprüfung ---
check_permissions() {
    if [ "$(id -u)" -eq 0 ]; then
        log_message "WARNING" "Skript wird als root ausgeführt."
        echo -e "${YELLOW}Warnung: Skript wird als root ausgeführt. Dies ist möglicherweise nicht erforderlich.${NC}"
        read -p "Fortfahren? (j/N): " confirm
        [[ ! "$confirm" =~ ^[jJ](a)?$ ]] && {
            log_message "INFO" "Skript abgebrochen (root-Ausführung nicht bestätigt)."
            exit 1
        }
    fi
}

# --- Autostart-Einrichtung ---
setup_autostart() {
    # Ermittle den tatsächlichen Pfad des aktuell ausgeführten Skripts
    local actual_script_path
    # Versuche, den absoluten Pfad mit readlink zu bekommen (zuverlässiger)
    if command -v readlink >/dev/null && actual_script_path=$(readlink -f "$0"); then
        : # Pfad erfolgreich ermittelt
    elif [[ "$0" == /* ]]; then # Wenn $0 bereits absolut ist
        actual_script_path="$0"
    else # Fallback, wenn readlink nicht geht oder $0 relativ ist
        actual_script_path="$(pwd)/$0"
        # Versuche, den Pfad zu normalisieren (entfernt . und ..)
        actual_script_path=$(cd "$(dirname "$actual_script_path")" 2>/dev/null && pwd || pwd)/$(basename "$actual_script_path")
    fi

    # Überprüfe, ob der Pfad ermittelt werden konnte und die Datei existiert
    if [ -z "$actual_script_path" ] || [ ! -f "$actual_script_path" ]; then
        log_message "ERROR" "Konnte den Pfad des aktuellen Skripts nicht zuverlässig ermitteln ('$0'). Autostart wird nicht eingerichtet."
        echo -e "${RED}Fehler: Konnte den Pfad des aktuellen Skripts nicht ermitteln. Autostart übersprungen.${NC}"
        return 1 # Beende die Funktion mit Fehlercode
    fi

    # Prüfe, ob der Autostart-Marker bereits existiert
    if ! grep -qF "$AUTOSTART_MARKER" "$BASHRC_FILE" 2>/dev/null; then
        log_message "INFO" "Richte Autostart für Skript '$actual_script_path' ein."
        echo -e "${YELLOW}INFO: Richte Autostart für dieses Skript ein ('$actual_script_path')...${NC}"
        # Stelle sicher, dass die .bashrc existiert
        touch "$BASHRC_FILE"
        # Füge den Autostart-Block hinzu (verwende geschweifte Klammern für Gruppierung)
        {
            echo ""
            echo "$AUTOSTART_MARKER"
            echo "# Führt das benutzerdefinierte Startskript aus, wenn es existiert"
            # Verwende den ermittelten Pfad, stelle sicher, dass er korrekt gequotet wird
            echo "if [ -f \"$actual_script_path\" ]; then"
            echo "   \"$actual_script_path\""
            echo "fi"
            echo ""
        } >> "$BASHRC_FILE"

        # Überprüfe, ob das Schreiben erfolgreich war
        if grep -qF "$actual_script_path" "$BASHRC_FILE"; then
             log_message "INFO" "Autostart erfolgreich in '$BASHRC_FILE' eingetragen."
             echo -e "${GREEN}Autostart erfolgreich in '$BASHRC_FILE' eingetragen.${NC}"
             echo -e "${YELLOW}Das Skript wird beim nächsten Start von Termux automatisch ausgeführt.${NC}"
             sleep 3
        else
             log_message "ERROR" "Fehler beim Schreiben des Autostart-Eintrags in '$BASHRC_FILE'."
             echo -e "${RED}Fehler: Konnte den Autostart-Eintrag nicht in '$BASHRC_FILE' schreiben.${NC}"
             sleep 3
             return 1 # Beende die Funktion mit Fehlercode
        fi
    # else # Optional: Hier könnte man prüfen, ob der *existierende* Eintrag korrekt ist
    #    existing_path=$(grep -A 1 "$AUTOSTART_MARKER" "$BASHRC_FILE" | grep -oP '(?<=if \[ -f ")[^"]+')
    #    if [ -n "$existing_path" ] && [ "$existing_path" != "$actual_script_path" ]; then
    #        log_message "WARNING" "Vorhandener Autostart-Eintrag zeigt auf '$existing_path', aber Skript ist unter '$actual_script_path'. Manuelle Korrektur empfohlen."
    #        echo -e "${YELLOW}Warnung: Vorhandener Autostart-Eintrag in '$BASHRC_FILE' scheint falsch zu sein. Bitte manuell prüfen.${NC}"
    #        sleep 5
    #    fi
    fi
    return 0 # Erfolgreich beendet
}

# --- Update-Funktion ---
update_script() {
    echo -e "${CYAN}${BOLD}🔄 Skript aktualisieren${NC}"
    log_message "INFO" "Starte Skript-Update von '$REPO_URL'."

    if [ -d "$(dirname "$SCRIPT_PATH")/.git" ]; then
        if ! check_command "git" "git"; then read -p "Weiter..."; return; fi
        echo -e "${CYAN}Skript ist in einem Git-Repository. Führe 'git pull' aus...${NC}"
        (
            cd "$(dirname "$SCRIPT_PATH")" || exit 1
            if git pull origin main 2>> "$LOG_FILE"; then
                log_message "INFO" "Git pull erfolgreich."
                echo -e "${GREEN}Skript erfolgreich aktualisiert (git pull).${NC}"
            else
                log_message "ERROR" "Fehler beim Ausführen von git pull."
                echo -e "${RED}Fehler beim Aktualisieren (git pull).${NC}"
                read -p "Weiter..."; return
            fi
        )
    else
        if ! check_command "wget" "wget"; then read -p "Weiter..."; return; fi
        echo -e "${CYAN}Kein Git-Repository. Lade Skript von '$RAW_SCRIPT_URL'...${NC}"
        temp_file="$HOME/startup.sh.tmp"
        if wget -O "$temp_file" "$RAW_SCRIPT_URL" 2>> "$LOG_FILE"; then
            if grep -q "^#!/bin/bash" "$temp_file"; then
                backup_file="$SCRIPT_PATH.bak"
                mv "$SCRIPT_PATH" "$backup_file" 2>> "$LOG_FILE" && {
                    log_message "INFO" "Backup des aktuellen Skripts erstellt: $backup_file"
                }
                mv "$temp_file" "$SCRIPT_PATH" 2>> "$LOG_FILE" && chmod +x "$SCRIPT_PATH" 2>> "$LOG_FILE"
                if [ $? -eq 0 ]; then
                    log_message "INFO" "Skript erfolgreich aktualisiert von '$RAW_SCRIPT_URL'."
                    echo -e "${GREEN}Skript erfolgreich aktualisiert.${NC}"
                    echo -e "${YELLOW}Starte das aktualisierte Skript neu...${NC}"
                    sleep 2
                    exec "$SCRIPT_PATH"
                else
                    log_message "ERROR" "Fehler beim Ersetzen des Skripts."
                    echo -e "${RED}Fehler beim Ersetzen des Skripts.${NC}"
                    mv "$backup_file" "$SCRIPT_PATH" 2>> "$LOG_FILE" && {
                        log_message "INFO" "Backup wiederhergestellt: $backup_file"
                        echo -e "${YELLOW}Backup wiederhergestellt.${NC}"
                    }
                fi
            else
                log_message "ERROR" "Heruntergeladene Datei ist ungültig."
                echo -e "${RED}Heruntergeladene Datei ist ungültig (kein Bash-Skript).${NC}"
                rm -f "$temp_file" 2>> "$LOG_FILE"
            fi
        else
            log_message "ERROR" "Fehler beim Herunterladen von '$RAW_SCRIPT_URL'."
            echo -e "${RED}Fehler beim Herunterladen des Skripts.${NC}"
            rm -f "$temp_file" 2>> "$LOG_FILE"
        fi
    fi
    read -p "Weiter..."
}

# --- Funktionen ---

# Funktion zum Anzeigen des Banners
show_banner() {
    clear
    echo -e "${GREEN}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🚀 BLACK-TERMUX-SHELL! 🚀       ${NC}"
    echo -e "${GREEN}${BOLD}=========================================${NC}"
    echo ""
}

# Funktion zum Anzeigen der Systeminformationen
show_sysinfo() {
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Systeminformationen:${NC}"
    MODEL=$(getprop ro.product.model) && [ -z "$MODEL" ] && MODEL="N/A"
    ANDROID_VERSION=$(getprop ro.build.version.release)
    KERNEL=$(uname -sr)
    STORAGE=$(df -h /data/data/com.termux/files/home | awk 'NR==2{print $4 "/" $2}')
    MEMORY=$(free -h | awk '/^Mem:/ {print $4 "/" $2}')
    UPTIME=$(uptime -p | sed 's/up //')
    echo -e " ${GREEN}📱 Modell:${NC} $MODEL"
    echo -e " ${GREEN}🤖 Android:${NC} $ANDROID_VERSION"
    echo -e " ${GREEN}🐧 Kernel:${NC} $KERNEL"
    echo -e " ${GREEN}💾 Speicher (~):${NC} $STORAGE frei"
    echo -e " ${GREEN}🧠 RAM:${NC} $MEMORY frei"
    echo -e " ${GREEN}⏱️ Laufzeit:${NC} $UPTIME"
    if command -v "$PYTHON_CMD" &> /dev/null; then
        PYTHON_VERSION=$("$PYTHON_CMD" --version 2>&1)
        echo -e " ${GREEN}🐍 Python:${NC} $PYTHON_VERSION"
    else
        echo -e " ${YELLOW}🐍 Python:${NC} Nicht installiert (pkg install python)"
    fi
    echo ""
}

# Funktion zum Überprüfen, ob ein Befehl existiert
check_command() {
    local cmd=$1
    local pkg=$2
    if ! command -v "$cmd" &> /dev/null; then
        log_message "ERROR" "'$cmd' ist nicht installiert (Paket: $pkg)."
        echo -e "${RED}Fehler: '$cmd' ist nicht installiert (Paket: $pkg).${NC}"
        read -p "Möchtest du '$pkg' jetzt installieren? (j/N): " install_confirm
        if [[ "$install_confirm" =~ ^[jJ](a)?$ ]]; then
            log_message "INFO" "Versuche Installation von '$pkg'..."
            run_with_progress "pkg update -y"
            if ! pkg install "$pkg" -y 2>> "$LOG_FILE"; then
                log_message "ERROR" "Installation von '$pkg' fehlgeschlagen."
                echo -e "${RED}Installation von '$pkg' fehlgeschlagen.${NC}"
                return 1
            else
                log_message "INFO" "'$pkg' erfolgreich installiert."
                echo -e "${GREEN}'$pkg' erfolgreich installiert.${NC}"
                return 0
            fi
        else
            log_message "INFO" "Installation von '$pkg' abgebrochen."
            echo -e "${YELLOW}Installation abgebrochen.${NC}"
            return 1
        fi
    fi
    return 0
}

# Funktion zum Überprüfen von Python und Pip
check_python_pip() {
    if ! check_command "$PYTHON_CMD" "python"; then return 1; fi
    if ! command -v pip &> /dev/null; then
        log_message "INFO" "Pip fehlt. Versuche Installation..."
        echo -e "${YELLOW}Pip scheint zu fehlen. Versuche 'pip' zu installieren/upzugraden...${NC}"
        "$PYTHON_CMD" -m ensurepip --upgrade
        "$PYTHON_CMD" -m pip install --upgrade pip
        if ! command -v pip &> /dev/null; then
            log_message "ERROR" "Konnte Pip nicht installieren/finden."
            echo -e "${RED}Konnte Pip nicht installieren/finden.${NC}"
            return 1
        fi
    fi
    return 0
}

# Funktion zur Sicherheitsprüfung von Python-Skripten
check_python_security() {
    local script=$1
    if grep -qE "os\.system|subprocess\.run|subprocess\.call|subprocess\.Popen" "$script"; then
        log_message "WARNING" "Skript '$script' enthält potenziell unsichere Befehle."
        echo -e "${YELLOW}Warnung: Skript enthält potenziell unsichere Befehle (z. B. os.system, subprocess).${NC}"
        read -p "Trotzdem ausführen? (j/N): " confirm
        [[ ! "$confirm" =~ ^[jJ](a)?$ ]] && return 1
    fi
    return 0
}

# Funktion zum automatischen Installieren fehlender Python-Module
auto_install_python_modules() {
    echo -e "${CYAN}${BOLD}🐍⚙️ Auto-Install Python Module${NC}"
    log_message "INFO" "Prüfe Python-Skripte in '$PYTHON_SCRIPT_DIR'..."
    echo -e "${CYAN}Prüfe Skripte in '$PYTHON_SCRIPT_DIR'...${NC}"

    if ! check_python_pip; then read -p "Weiter..."; return; fi
    if [ ! -d "$PYTHON_SCRIPT_DIR" ]; then
        log_message "WARNING" "'$PYTHON_SCRIPT_DIR' nicht gefunden."
        echo -e "${YELLOW}Warnung: '$PYTHON_SCRIPT_DIR' nicht gefunden.${NC}"
        echo -e "${YELLOW}Erstelle Ordner & gib Speicherzugriff ('termux-setup-storage').${NC}"
        read -p "Weiter..."; return
    fi

    echo -e "${BLUE}Suche Imports...${NC}"
    required_modules=$(grep -h -E -o '^\s*(import|from)\s+([a-zA-Z0-9_]+)' "$PYTHON_SCRIPT_DIR"/*.py 2>/dev/null | awk '{print $2}' | grep -v '^\.' | sort -u)

    if [ -z "$required_modules" ]; then
        log_message "INFO" "Keine externen Module gefunden oder Ordner leer."
        echo -e "${GREEN}Keine externen Module gefunden oder Ordner leer.${NC}"; read -p "Weiter..."; return
    fi

    echo -e "${BLUE}Potenzielle Module:${NC} $required_modules"
    missing_modules=()
    echo -e "${BLUE}Prüfe Installation...${NC}"

    standard_modules="os sys math random json datetime time argparse re collections itertools functools subprocess logging threading multiprocessing asyncio pathlib select socket struct enum codecs bisect calendar cmath copy csv decimal email fractions getopt glob hashlib heapq io locale operator pickle queue shutil signal stat string tempfile uuid warnings weakref xml zlib"

    for module in $required_modules; do
        if echo "$standard_modules" | grep -qw "$module"; then
            echo -e " - ${CYAN}$module (Standardmodul, ignoriert)${NC}"
            continue
        fi

        if ! pip show "$module" &> /dev/null; then
            echo -e " - ${YELLOW}$module fehlt${NC}"
            missing_modules+=("$module")
        else
            echo -e " - ${GREEN}$module bereits installiert${NC}"
        fi
    done

    if [ ${#missing_modules[@]} -eq 0 ]; then
        log_message "INFO" "Alle benötigten Module sind installiert oder Standardmodule."
        echo -e "${GREEN}Alle benötigten externen Module sind installiert oder Standardmodule.${NC}"
    else
        echo -e "${YELLOW}Fehlende Module:${NC} ${missing_modules[*]}"
        read -p "Versuchen, diese zu installieren? (j/N): " install_confirm
        if [[ "$install_confirm" =~ ^[jJ](a)?$ ]]; then
            echo -e "${CYAN}Installiere: ${missing_modules[*]}...${NC}"
            for module in "${missing_modules[@]}"; do
                echo -e "${BLUE}Installiere $module...${NC}"
                if pip install "$module" 2>> "$LOG_FILE"; then
                    log_message "INFO" "Modul $module erfolgreich installiert."
                    echo -e "${GREEN}$module erfolgreich installiert.${NC}"
                else
                    log_message "ERROR" "Fehler beim Installieren von $module."
                    echo -e "${RED}Fehler beim Installieren von $module, fahre fort...${NC}"
                fi
            done
            log_message "INFO" "Installation abgeschlossen."
            echo -e "${GREEN}Installation abgeschlossen (einige Module könnten fehlerhaft sein).${NC}"
        else
            log_message "INFO" "Installation abgebrochen."
            echo -e "${YELLOW}Installation abgebrochen.${NC}"
        fi
    fi
    read -p "Weiter..."
}

# Funktion zum Starten eines Python-Skripts (mit Debugging-Option)
start_python_script() {
    echo -e "${CYAN}${BOLD}▶️🐍 Python Skript starten${NC}"
    log_message "INFO" "Suche Python-Skripte in '$PYTHON_SCRIPT_DIR'..."
    echo -e "${CYAN}Suche in '$PYTHON_SCRIPT_DIR'...${NC}"

    if ! check_python_pip; then read -p "Weiter..."; return; fi
    if [ ! -d "$PYTHON_SCRIPT_DIR" ]; then
        log_message "ERROR" "'$PYTHON_SCRIPT_DIR' nicht gefunden."
        echo -e "${RED}Fehler: '$PYTHON_SCRIPT_DIR' nicht gefunden.${NC}"; read -p "Weiter..."; return
    fi

    mapfile -t py_scripts < <(find "$PYTHON_SCRIPT_DIR" -maxdepth 1 -name "*.py" -printf "%f\n" | sort)

    if [ ${#py_scripts[@]} -eq 0 ]; then
        log_message "WARNING" "Keine .py-Skripte in '$PYTHON_SCRIPT_DIR' gefunden."
        echo -e "${YELLOW}Keine .py-Skripte in '$PYTHON_SCRIPT_DIR' gefunden.${NC}"; read -p "Weiter..."; return
    fi

    echo -e "${YELLOW}Verfügbare Skripte:${NC}"
    i=1; for script in "${py_scripts[@]}"; do echo -e " ${MAGENTA}$i)${NC} $script"; ((i++)); done
    echo -e " ${MAGENTA}d)${NC} Skript mit Debugging (pdb)"
    echo ""

    read -p "$(echo -e "${BLUE}Wähle Skript [Nummer/d]: ${NC}")" script_choice
    if [ "$script_choice" = "d" ]; then
        echo -e "${YELLOW}Debug-Modus: Wähle ein Skript zum Debuggen${NC}"
        i=1; for script in "${py_scripts[@]}"; do echo -e " ${MAGENTA}$i)${NC} $script"; ((i++)); done
        read -p "$(echo -e "${BLUE}Skript [Nummer]: ${NC}")" debug_choice
        if ! [[ "$debug_choice" =~ ^[0-9]+$ ]] || [ "$debug_choice" -lt 1 ] || [ "$debug_choice" -gt ${#py_scripts[@]} ]; then
            log_message "ERROR" "Ungültige Skriptauswahl: $debug_choice"
            echo -e "${RED}Ungültige Auswahl.${NC}"; read -p "Weiter..."; return
        fi
        selected_script_index=$((debug_choice - 1))
        script_to_run="${PYTHON_SCRIPT_DIR}/${py_scripts[$selected_script_index]}"
        if check_python_security "$script_to_run"; then
            echo -e "${CYAN}Starte '${py_scripts[$selected_script_index]}' mit pdb...${NC}"
            log_message "INFO" "Führe Skript '${py_scripts[$selected_script_index]}' mit pdb aus."
            "$PYTHON_CMD" -m pdb "$script_to_run"
            log_message "INFO" "Debugging beendet: '${py_scripts[$selected_script_index]}'."
            echo -e "${GREEN}Debugging beendet.${NC}"
        fi
    elif ! [[ "$script_choice" =~ ^[0-9]+$ ]] || [ "$script_choice" -lt 1 ] || [ "$script_choice" -gt ${#py_scripts[@]} ]; then
        log_message "ERROR" "Ungültige Skriptauswahl: $script_choice"
        echo -e "${RED}Ungültige Auswahl.${NC}"; read -p "Weiter..."; return
    else
        selected_script_index=$((script_choice - 1))
        script_to_run="${PYTHON_SCRIPT_DIR}/${py_scripts[$selected_script_index]}"
        if check_python_security "$script_to_run"; then
            echo -e "${CYAN}Führe aus: '${py_scripts[$selected_script_index]}'...${NC}"
            log_message "INFO" "Führe Skript '${py_scripts[$selected_script_index]}' aus."
            echo "--- Skript-Ausgabe Start ---"
            cd "$(dirname "$script_to_run")" && "$PYTHON_CMD" "$(basename "$script_to_run")" && cd "$HOME"
            echo "--- Skript-Ausgabe Ende ---"
            log_message "INFO" "Skriptausführung beendet: '${py_scripts[$selected_script_index]}'."
            echo -e "${GREEN}Skriptausführung beendet.${NC}"
        fi
    fi
    read -p "Weiter..."
}

# Funktion zum manuellen Installieren von Python-Modulen
manual_install_python_modules() {
    echo -e "${CYAN}${BOLD}🛠️🐍 Python Module installieren (pip)${NC}"
    log_message "INFO" "Starte manuelle Modul-Installation."
    if ! check_python_pip; then read -p "Weiter..."; return; fi

    read -p "$(echo -e "${BLUE}Module eingeben (getrennt durch Leerzeichen, z. B. requests==2.28.1): ${NC}")" modules_to_install
    if [ -z "$modules_to_install" ]; then
        log_message "WARNING" "Keine Module angegeben."
        echo -e "${YELLOW}Keine Module angegeben.${NC}"
    else
        echo -e "${CYAN}Installiere: $modules_to_install...${NC}"
        for module in $modules_to_install; do
            if pip install "$module" 2>> "$LOG_FILE"; then
                log_message "INFO" "Modul $module erfolgreich installiert."
                echo -e "${GREEN}$module installiert.${NC}"
            else
                log_message "ERROR" "Fehler beim Installieren von $module."
                echo -e "${RED}Fehler beim Installieren von $module.${NC}"
            fi
        done
    fi
    read -p "Weiter..."
}

# Funktion zum Deinstallieren von Python-Modulen
uninstall_python_modules() {
    echo -e "${CYAN}${BOLD}🗑️🐍 Python Module deinstallieren (pip)${NC}"
    log_message "INFO" "Starte Modul-Deinstallation."
    if ! check_python_pip; then read -p "Weiter..."; return; fi

    installed_modules=$(pip list --format=freeze | cut -d'=' -f1)
    echo -e "${YELLOW}Installierte Module:${NC} $installed_modules"
    read -p "$(echo -e "${BLUE}Module zum Deinstallieren (Leerzeichen getrennt): ${NC}")" modules_to_uninstall
    if [ -z "$modules_to_uninstall" ]; then
        log_message "WARNING" "Keine Module angegeben."
        echo -e "${YELLOW}Keine Module angegeben.${NC}"
    else
        echo -e "${CYAN}Deinstalliere: $modules_to_uninstall...${NC}"
        for module in $modules_to_uninstall; do
            if pip uninstall "$module" -y 2>> "$LOG_FILE"; then
                log_message "INFO" "Modul $module erfolgreich deinstalliert."
                echo -e "${GREEN}$module deinstalliert.${NC}"
            else
                log_message "ERROR" "Fehler beim Deinstallieren von $module."
                echo -e "${RED}Fehler beim Deinstallieren von $module.${NC}"
            fi
        done
    fi
    read -p "Weiter..."
}

# Funktion für Git-Operationen
git_helper() {
    echo -e "${CYAN}${BOLD}🐙 Git Helfer${NC}"
    log_message "INFO" "Starte Git-Helfer."
    if ! check_command "git" "git"; then read -p "Weiter..."; return; fi

    read -e -p "$(echo -e "${BLUE}Pfad zum Git-Repo [leer für $HOME]: ${NC}")" repo_path
    [ -z "$repo_path" ] && repo_path="$HOME"

    if [ ! -d "$repo_path" ] || [ ! -d "$repo_path/.git" ]; then
        log_message "ERROR" "'$repo_path' ist kein gültiges Git-Repository."
        echo -e "${RED}Fehler: '$repo_path' ist kein gültiges Git-Repository.${NC}"
        read -p "Weiter..."; return
    fi

    echo -e "${YELLOW}Aktionen für '$repo_path':${NC}"
    echo -e " ${MAGENTA}1)${NC} Status anzeigen (git status)"
    echo -e " ${MAGENTA}2)${NC} Änderungen holen (git pull)"
    echo -e " ${MAGENTA}3)${NC} Änderungen committen (git commit)"
    echo -e " ${MAGENTA}4)${NC} Änderungen pushen (git push)"
    read -p "$(echo -e "${BLUE}Wähle Aktion [1-4]: ${NC}")" git_action

    (
        cd "$repo_path" || exit 1
        case $git_action in
            1) echo -e "${CYAN}Führe 'git status' aus...${NC}"; git status;;
            2) echo -e "${CYAN}Führe 'git pull' aus...${NC}"; git pull;;
            3)
                echo -e "${CYAN}Führe 'git commit' aus...${NC}"
                read -p "$(echo -e "${BLUE}Commit-Nachricht: ${NC}")" commit_msg
                if [ -n "$commit_msg" ]; then
                    git add . && git commit -m "$commit_msg"
                    log_message "INFO" "Git commit erfolgreich: $commit_msg"
                else
                    log_message "ERROR" "Keine Commit-Nachricht angegeben."
                    echo -e "${RED}Keine Commit-Nachricht angegeben.${NC}"
                fi
                ;;
            4) echo -e "${CYAN}Führe 'git push' aus...${NC}"; git push;;
            *) log_message "ERROR" "Ungültige Git-Aktion: $git_action"; echo -e "${RED}Ungültige Auswahl.${NC}";;
        esac
    )
    read -p "Weiter..."
}

# Funktion für Netzwerk-Scan (mit Port-Scan)
network_scan() {
    echo -e "${CYAN}${BOLD}📡 Netzwerk Scan${NC}"
    log_message "INFO" "Starte Netzwerk-Scan."
    if ! check_command "nmap" "nmap"; then read -p "Weiter..."; return; fi

    local_ip=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null || ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    default_target=""
    if [ -n "$local_ip" ]; then
        subnet=$(echo "$local_ip" | cut -d. -f1-3).0/24
        default_target="$subnet"
        echo -e "${BLUE}Lokales Subnetz erkannt: $subnet ${NC}"
    fi

    echo -e "${YELLOW}Scan-Typ:${NC}"
    echo -e " ${MAGENTA}1)${NC} Ping-Scan (schnell)"
    echo -e " ${MAGENTA}2)${NC} TCP-Port-Scan"
    echo -e " ${MAGENTA}3)${NC} UDP-Port-Scan"
    read -p "$(echo -e "${BLUE}Wähle Scan [1-3]: ${NC}")" scan_type
    read -p "$(echo -e "${BLUE}Ziel-IP/Subnetz [Standard: $default_target]: ${NC}")" target
    [ -z "$target" ] && target="$default_target"

    if [ -z "$target" ]; then
        log_message "ERROR" "Kein Ziel für Netzwerk-Scan angegeben."
        echo -e "${RED}Kein Ziel angegeben/gefunden.${NC}"; read -p "Weiter..."; return
    fi

    echo -e "${CYAN}Starte Scan für '$target'... (Kann dauern)${NC}"
    case $scan_type in
        1) nmap -sn "$target";;
        2) nmap -sT "$target";;
        3) nmap -sU "$target";;
        *) log_message "ERROR" "Ungültiger Scan-Typ: $scan_type"; echo -e "${RED}Ungültige Auswahl.${NC}";;
    esac
    log_message "INFO" "Netzwerk-Scan für '$target' abgeschlossen."
    echo -e "${GREEN}Scan beendet.${NC}"
    read -p "Weiter..."
}

# Funktion zum Bearbeiten der .bashrc
edit_bashrc() {
    echo -e "${CYAN}${BOLD}📝 .bashrc bearbeiten${NC}"
    log_message "INFO" "Öffne .bashrc zum Bearbeiten."
    if ! check_command "nano" "nano"; then read -p "Weiter..."; return; fi
    echo -e "${BLUE}Öffne '$BASHRC_FILE' mit nano...${NC}"
    nano "$BASHRC_FILE"
    log_message "INFO" "Bearbeitung von .bashrc abgeschlossen."
    echo -e "${GREEN}Bearbeitung beendet. Änderungen werden beim nächsten Start wirksam.${NC}"
    read -p "Weiter..."
}

# Funktion für Termux-Backup
backup_termux() {
    echo -e "${CYAN}${BOLD}💾 Termux Backup${NC}"
    log_message "INFO" "Starte Termux-Backup."
    if ! check_command "tar" "tar"; then read -p "Weiter..."; return; fi

    backup_dir="$HOME/storage/shared/termux_backups"
    backup_file="$backup_dir/termux_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir" || {
            log_message "ERROR" "Konnte Backup-Verzeichnis '$backup_dir' nicht erstellen."
            echo -e "${RED}Konnte Backup-Verzeichnis '$backup_dir' nicht erstellen.${NC}"
            read -p "Weiter..."; return
        }
    fi

    echo -e "${CYAN}Erstelle Backup von $HOME nach $backup_file...${NC}"
    if tar -czf "$backup_file" -C "$HOME" . 2>> "$LOG_FILE"; then
        log_message "INFO" "Backup erfolgreich erstellt: $backup_file"
        echo -e "${GREEN}Backup erfolgreich erstellt: $backup_file${NC}"
    else
        log_message "ERROR" "Fehler beim Erstellen des Backups."
        echo -e "${RED}Fehler beim Erstellen des Backups.${NC}"
    fi
    read -p "Weiter..."
}

# Funktion für SSH-Server-Verwaltung
manage_ssh() {
    echo -e "${CYAN}${BOLD}🔒 SSH-Server Verwaltung${NC}"
    log_message "INFO" "Starte SSH-Server-Verwaltung."
    if ! check_command "sshd" "openssh"; then read -p "Weiter..."; return; fi

    echo -e "${YELLOW}Aktionen:${NC}"
    echo -e " ${MAGENTA}1)${NC} SSH-Server starten"
    echo -e " ${MAGENTA}2)${NC} SSH-Server stoppen"
    echo -e " ${MAGENTA}3)${NC} Status prüfen"
    read -p "$(echo -e "${BLUE}Wähle Aktion [1-3]: ${NC}")" ssh_action

    case $ssh_action in
        1)
            echo -e "${CYAN}Starte SSH-Server...${NC}"
            if pkill sshd && sshd; then
                log_message "INFO" "SSH-Server gestartet."
                echo -e "${GREEN}SSH-Server gestartet.${NC}"
            else
                log_message "ERROR" "Fehler beim Starten des SSH-Servers."
                echo -e "${RED}Fehler beim Starten des SSH-Servers.${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Stoppe SSH-Server...${NC}"
            if pkill sshd; then
                log_message "INFO" "SSH-Server gestoppt."
                echo -e "${GREEN}SSH-Server gestoppt.${NC}"
            else
                log_message "ERROR" "Fehler beim Stoppen des SSH-Servers."
                echo -e "${RED}Fehler beim Stoppen des SSH-Servers.${NC}"
            fi
            ;;
        3)
            if pgrep sshd > /dev/null; then
                log_message "INFO" "SSH-Server läuft."
                echo -e "${GREEN}SSH-Server läuft.${NC}"
            else
                log_message "INFO" "SSH-Server läuft nicht."
                echo -e "${YELLOW}SSH-Server läuft nicht.${NC}"
            fi
            ;;
        *)
            log_message "ERROR" "Ungültige SSH-Aktion: $ssh_action"
            echo -e "${RED}Ungültige Auswahl.${NC}"
            ;;
    esac
    read -p "Weiter..."
}

# Funktion zum Bearbeiten der Konfigurationsdatei
edit_config() {
    echo -e "${CYAN}${BOLD}⚙️ Konfiguration bearbeiten${NC}"
    log_message "INFO" "Öffne Konfigurationsdatei '$CONFIG_FILE' zum Bearbeiten."
    if ! check_command "nano" "nano"; then read -p "Weiter..."; return; fi
    nano "$CONFIG_FILE"
    source "$CONFIG_FILE"
    if [ ! -d "$PYTHON_SCRIPT_DIR" ]; then
        log_message "WARNING" "PYTHON_SCRIPT_DIR ($PYTHON_SCRIPT_DIR) existiert nicht."
        echo -e "${YELLOW}Warnung: PYTHON_SCRIPT_DIR ($PYTHON_SCRIPT_DIR) existiert nicht.${NC}"
    fi
    if ! echo "default dark mib light" | grep -qw "$THEME"; then
        log_message "WARNING" "Ungültiges Theme: $THEME. Setze auf 'default'."
        echo -e "${YELLOW}Warnung: Ungültiges Theme ($THEME). Setze auf 'default'.${NC}"
        sed -i "s/THEME=.*/THEME=\"default\"/" "$CONFIG_FILE"
    fi
    load_theme
    log_message "INFO" "Konfiguration bearbeitet."
    echo -e "${GREEN}Konfiguration gespeichert.${NC}"
    read -p "Weiter..."
}

# Funktion zum Synchronisieren von Plugins aus dem Repository
sync_plugins() {
    echo -e "${CYAN}${BOLD}🔌 Synchronisiere Plugins aus Repository${NC}"
    log_message "INFO" "Starte Plugin-Synchronisation von '$PLUGIN_REPO_URL'."
    if ! check_command "wget" "wget"; then read -p "Weiter..."; return; fi

    mkdir -p "$PLUGIN_DIR" || {
        log_message "ERROR" "Konnte Plugin-Verzeichnis '$PLUGIN_DIR' nicht erstellen."
        echo -e "${RED}Konnte Plugin-Verzeichnis '$PLUGIN_DIR' nicht erstellen.${NC}"
        read -p "Weiter..."; return
    }

    # Bekannte Plugin-Liste definieren (statt zu versuchen, die HTML-Seite zu parsen)
    known_plugins=("backup_manager.sh" "file_cleaner.sh" "network_monitor.sh" "system_info.sh" "task_scheduler.sh")
    
    echo -e "${CYAN}Lade bekannte Plugins von '$PLUGIN_REPO_URL'...${NC}"
    
    # Temporäres Verzeichnis für Downloads
    temp_dir="$HOME/.termux_is_black_plugins_temp"
    mkdir -p "$temp_dir" || {
        log_message "ERROR" "Konnte temporäres Verzeichnis '$temp_dir' nicht erstellen."
        echo -e "${RED}Konnte temporäres Verzeichnis '$temp_dir' nicht erstellen.${NC}"
        read -p "Weiter..."; return
    }

    plugin_count=0
    for plugin in "${known_plugins[@]}"; do
        plugin_url="${PLUGIN_REPO_URL}${plugin}"
        plugin_path="$PLUGIN_DIR/$plugin"
        temp_path="$temp_dir/$plugin"
        
        echo -e "${CYAN}Lade $plugin...${NC}"
        if wget -q -O "$temp_path" "$plugin_url" 2>> "$LOG_FILE"; then
            if grep -q "^run_" "$temp_path"; then
                # Mit explizitem chmod +x für alle heruntergeladenen Plugins
                mv "$temp_path" "$plugin_path" && chmod +x "$plugin_path"
                log_message "INFO" "Plugin '$plugin' erfolgreich heruntergeladen und installiert (ausführbar)."
                echo -e "${GREEN}Plugin '$plugin' installiert und ausführbar gemacht.${NC}"
                ((plugin_count++))
            else
                log_message "ERROR" "Plugin '$plugin' ist ungültig (keine run_ Funktion gefunden)."
                echo -e "${RED}Plugin '$plugin' ist ungültig (keine run_ Funktion).${NC}"
                rm -f "$temp_path"
            fi
        else
            log_message "ERROR" "Fehler beim Herunterladen von '$plugin'."
            echo -e "${RED}Fehler beim Herunterladen von '$plugin'.${NC}"
            rm -f "$temp_path"
        fi
    done

    # Alle vorhandenen Plugins ausführbar machen (zur Sicherheit)
    if [ -d "$PLUGIN_DIR" ] && [ "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]; then
        chmod +x "$PLUGIN_DIR"/*.sh 2>/dev/null
        log_message "INFO" "Alle vorhandenen Plugins wurden ausführbar gemacht."
    fi

    rm -rf "$temp_dir"
    
    if [ $plugin_count -eq 0 ]; then
        log_message "WARNING" "Keine Plugins gefunden oder heruntergeladen."
        echo -e "${YELLOW}Keine Plugins erfolgreich synchronisiert.${NC}"
    else
        log_message "INFO" "Plugin-Synchronisation abgeschlossen: $plugin_count Plugins synchronisiert."
        echo -e "${GREEN}Plugin-Synchronisation abgeschlossen: $plugin_count Plugins synchronisiert.${NC}"
    fi
}

# Funktion zum Laden von Plugins
load_plugins() {
    mkdir -p "$PLUGIN_DIR"
    plugin_count=0
    # Nur Option 24 anzeigen, keine Auflistung der Plugins im Hauptmenü
    echo -e " ${BLUE}24)${NC} Plugins synchronisieren und auswählen"
    return $plugin_count
}

# Funktion für das interaktive Tutorial
show_tutorial() {
    echo -e "${CYAN}${BOLD}📚 Tutorial: Termux-is-Black${NC}"
    log_message "INFO" "Starte interaktives Tutorial."
    echo -e "${YELLOW}Willkommen! Dieses Skript hilft dir, Termux zu verwalten. Wähle eine Funktion zum Erkunden:${NC}"
    echo -e " ${MAGENTA}1)${NC} Python-Skripte ausführen"
    echo -e " ${MAGENTA}2)${NC} System aktualisieren"
    echo -e " ${MAGENTA}3)${NC} Netzwerk-Scan"
    echo -e " ${MAGENTA}4)${NC} Backup erstellen"
    read -p "$(echo -e "${BLUE}Wähle [1-4]: ${NC}")" choice
    case $choice in
        1)
            echo -e "${GREEN}Tutorial: Python-Skripte ausführen${NC}"
            echo -e "1. Kopiere ein .py-Skript nach '$PYTHON_SCRIPT_DIR' (z. B. mit 'cp script.py $PYTHON_SCRIPT_DIR')."
            echo -e "2. Wähle 'Python Skript starten' (Option 2) im Hauptmenü."
            echo -e "3. Wähle das Skript aus der Liste. Für Debugging gib 'd' ein."
            echo -e "${YELLOW}Tipp: Nutze 'Py-Module Auto-Install' (Option 1), um fehlende Module zu installieren.${NC}"
            ;;
        2)
            echo -e "${GREEN}Tutorial: System aktualisieren${NC}"
            echo -e "1. Wähle 'Update System' (Option 5) im Hauptmenü."
            echo -e "2. Das Skript führt 'pkg update && pkg upgrade' aus."
            echo -e "${YELLOW}Tipp: Stelle sicher, dass du eine Internetverbindung hast.${NC}"
            ;;
        3)
            echo -e "${GREEN}Tutorial: Netzwerk-Scan${NC}"
            echo -e "1. Wähle 'Netzwerk Scan' (Option 10) im Hauptmenü."
            echo -e "2. Wähle einen Scan-Typ (Ping, TCP, UDP) und gib ein Ziel ein (z. B. 192.168.1.0/24)."
            echo -e "${YELLOW}Tipp: Ping-Scans sind schneller, Port-Scans detaillierter.${NC}"
            ;;
        4)
            echo -e "${GREEN}Tutorial: Backup erstellen${NC}"
            echo -e "1. Wähle 'Termux Backup' (Option 12) im Hauptmenü."
            echo -e "2. Das Skript erstellt ein .tar.gz-Backup von deinem Home-Verzeichnis."
            echo -e "${YELLOW}Tipp: Backups werden in '~/storage/shared/termux_backups' gespeichert.${NC}"
            ;;
        *)
            echo -e "${RED}Ungültige Auswahl.${NC}"
            ;;
    esac
    log_message "INFO" "Tutorial für Option $choice abgeschlossen."
    read -p "Weiter..."
}

# Funktion zum Anzeigen des Menüs
show_menu() {
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Hauptmenü:${NC}"
    echo ""

    # Python-Optionen
    echo -e "${MAGENTA}${BOLD}🐍 Python-Optionen${NC}"
    echo -e "${WHITE}----------${NC}"
    echo -e " ${GREEN} 1) 🐍⚙️ Py-Module Auto-Install${NC}"
    echo -e " ${GREEN} 2) ▶️🐍 Python Skript starten${NC}"
    echo -e " ${GREEN} 3) 🛠️🐍 Py-Module Manuell ${NC}(pip)"
    echo -e " ${GREEN} 4) 🗑️🐍 Py-Module Deinstallieren ${NC}(pip)"
    echo ""

    # pkg-Optionen
    echo -e "${CYAN}${BOLD}📦 pkg-Optionen${NC}"
    echo -e "${WHITE}----------${NC}"
    echo -e " ${CYAN} 5) 🔄 Update System ${NC}(pkg)"
    echo -e " ${CYAN} 6) 📁 Dateimanager ${NC}(mc)"
    echo -e " ${CYAN} 7) 📊 Prozesse ${NC}(htop)"
    echo -e " ${CYAN} 8) 🌐 Netzwerk Info ${NC}(ifconfig)"
    echo -e " ${CYAN} 9) 📦 Paket installieren ${NC}(pkg)"
    echo ""

    # Netzwerk/Sicherheit
    echo -e "${BLUE}${BOLD}🌐 Netzwerk & Sicherheit${NC}"
    echo -e "${WHITE}----------${NC}"
    echo -e " ${BLUE}10) 📡 Netzwerk Scan ${NC}(nmap)"
    echo -e " ${BLUE}11) 🔒 SSH-Server Verwaltung ${NC}(sshd)"
    echo ""

    # Backup/Git/Update
    echo -e "${GREEN}${BOLD}💾 Backup, Git & Update${NC}"
    echo -e "${WHITE}----------${NC}"
    echo -e " ${BLUE}12) 💾 Termux Backup ${NC}(tar)"
    echo -e " ${BLUE}13) 🐙 Git Helfer ${NC}(status/pull/commit/push)"
    echo -e " ${BLUE}14) 🔄 Skript aktualisieren ${NC}(github)"
    echo ""

    # Sonstiges
    echo -e "${YELLOW}${BOLD}⚙️ Sonstiges${NC}"
    echo -e "${WHITE}----------${NC}"
    echo -e " ${BLUE}15) 📝 .bashrc bearbeiten ${NC}(nano)"
    echo -e " ${BLUE}16) ⚙️ Konfiguration bearbeiten ${NC}(nano)"
    echo -e " ${BLUE}17) 📚 Interaktives Tutorial${NC}"
    echo -e " ${RED}18) 🚪 Beenden${NC}"
    echo ""

    # Plugins
    echo -e "${MAGENTA}${BOLD}🔌 Plugins${NC}"
    echo -e "${WHITE}----------${NC}"
    load_plugins
    plugin_count=$?
    echo ""
}

# --- Hauptlogik ---

# Lade Konfiguration und Theme
load_config
load_theme

# Sicherheitsprüfung
check_permissions

# Autostart einrichten
if [ -t 1 ] && [ -z "$TERMUX_SCRIPT_STARTUP_RUNNING" ]; then
    setup_autostart
fi

# Setze Variable für Autostart
export TERMUX_SCRIPT_STARTUP_RUNNING=true

# Hauptschleife
while true; do
    show_banner
    show_sysinfo
    show_menu

    read -p "$(echo -e "${WHITE}${BOLD}Wähle eine Option [1-$((18 + plugin_count))]: ${NC}")" choice

    case $choice in
        1) auto_install_python_modules;;
        2) start_python_script;;
        3) manual_install_python_modules;;
        4) uninstall_python_modules;;
        5) run_with_progress "pkg update && pkg upgrade -y"; read -p "Weiter...";;
        6) echo -e "${CYAN}🚀 Starte Dateimanager...${NC}"; if check_command "mc" "mc"; then mc; else read -p "Weiter..."; fi;;
        7) echo -e "${CYAN}🚀 Starte Prozessliste...${NC}"; if check_command "htop" "htop"; then htop; else read -p "Weiter..."; fi;;
        8) echo -e "${CYAN}🔎 Zeige Netzwerk Info...${NC}"; if check_command "ifconfig" "net-tools"; then ifconfig; else read -p "Weiter..."; fi; read -p "Weiter...";;
        9) read -p "$(echo -e "${BLUE}Zu installierende pkg-Pakete: ${NC}")" packages; if [ -n "$packages" ]; then echo -e "${CYAN}Installiere: $packages...${NC}"; pkg install $packages -y 2>> "$LOG_FILE"; else echo -e "${YELLOW}Keine Pakete angegeben.${NC}"; fi; read -p "Weiter...";;
        10) network_scan;;
        11) manage_ssh;;
        12) backup_termux;;
        13) git_helper;;
        14) update_script;;
        15) edit_bashrc;;
        16) edit_config;;
        17) show_tutorial;;
        18) echo -e "${GREEN}👋 Auf Wiedersehen!${NC}"; log_message "INFO" "Skript beendet."; unset TERMUX_SCRIPT_STARTUP_RUNNING; exit 0;;
        24)
            sync_plugins
            
            # Alle gefundenen Plugins automatisch ausführbar machen
            echo -e "${CYAN}Mache alle Plugins ausführbar...${NC}"
            if [ -d "$PLUGIN_DIR" ]; then
                chmod +x "$PLUGIN_DIR"/*.sh 2>/dev/null
                log_message "INFO" "Alle Plugins wurden ausführbar gemacht."
                echo -e "${GREEN}Alle Plugins wurden ausführbar gemacht.${NC}"
            fi
            
            echo -e "${CYAN}Verfügbare Plugins in: $PLUGIN_DIR${NC}"
            plugin_files=("$PLUGIN_DIR"/*.sh)
            if [ ${#plugin_files[@]} -eq 0 ] || [ ! -f "${plugin_files[0]}" ]; then
                echo -e "${YELLOW}Keine Plugins gefunden. Versuche die Synchronisierung erneut.${NC}"
            else
                echo -e "${YELLOW}Wähle ein Plugin zum Ausführen:${NC}"
                for i in "${!plugin_files[@]}"; do
                    plugin_name=$(basename "${plugin_files[$i]}" .sh)
                    echo -e " ${MAGENTA}$((i+1)))${NC} $plugin_name"
                done
                read -p "$(echo -e "${BLUE}Plugin auswählen [1-${#plugin_files[@]}] oder 0 zum Abbrechen: ${NC}")" plugin_choice
                if [[ "$plugin_choice" =~ ^[0-9]+$ ]] && [ "$plugin_choice" -ge 1 ] && [ "$plugin_choice" -le ${#plugin_files[@]} ]; then
                    selected_plugin="${plugin_files[$((plugin_choice-1))]}"
                    plugin_name=$(basename "$selected_plugin" .sh)
                    if [ -f "$selected_plugin" ]; then
                        source "$selected_plugin"
                        if type "run_$plugin_name" &>/dev/null; then
                            log_message "INFO" "Führe Plugin '$plugin_name' aus."
                            echo -e "${GREEN}Starte Plugin: $plugin_name${NC}"
                            "run_$plugin_name"
                        else
                            log_message "ERROR" "Plugin '$plugin_name' hat keine run_$plugin_name Funktion."
                            echo -e "${RED}Plugin '$plugin_name' kann nicht ausgeführt werden (fehlende run_$plugin_name Funktion).${NC}"
                        fi
                    else
                        log_message "ERROR" "Plugin '$plugin_name' nicht gefunden."
                        echo -e "${RED}Plugin nicht gefunden.${NC}"
                    fi
                elif [ "$plugin_choice" != "0" ]; then
                    log_message "ERROR" "Ungültige Plugin-Auswahl: $plugin_choice"
                    echo -e "${RED}Ungültige Auswahl.${NC}"
                fi
            fi
            read -p "Weiter..."
            ;;
        *)
            log_message "ERROR" "Ungültige Menüauswahl: $choice"
            echo -e "${RED}🚨 Ungültige Auswahl.${NC}"
            sleep 2
            ;;
    esac
done
