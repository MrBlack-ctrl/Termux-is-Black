#!/bin/bash

# --- Konfiguration ---
CONFIG_FILE="$HOME/.termux_startup.conf"
LOG_FILE="$HOME/termux_startup.log"
REPO_URL="https://github.com/MrBlack-ctrl/Termux-is-Black"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/startup.sh"

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
EOF
        source "$CONFIG_FILE"
        log_message "INFO" "Standardkonfiguration '$CONFIG_FILE' erstellt."
    fi
    SCRIPT_PATH="$HOME/$SCRIPT_NAME"
}

# --- Farben und Stil ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # Keine Farbe (Reset)

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
    if ! grep -qF "$AUTOSTART_MARKER" "$BASHRC_FILE" 2>/dev/null; then
        log_message "INFO" "Richte Autostart für Skript ein."
        echo -e "${YELLOW}INFO: Richte Autostart für dieses Skript ein...${NC}"
        echo "" >> "$BASHRC_FILE"
        echo "$AUTOSTART_MARKER" >> "$BASHRC_FILE"
        echo "# Führt das benutzerdefinierte Startskript aus, wenn es existiert" >> "$BASHRC_FILE"
        echo "if [ -f \"$SCRIPT_PATH\" ]; then" >> "$BASHRC_FILE"
        echo "   \"$SCRIPT_PATH\"" >> "$BASHRC_FILE"
        echo "fi" >> "$BASHRC_FILE"
        echo "" >> "$BASHRC_FILE"
        log_message "INFO" "Autostart erfolgreich in '$BASHRC_FILE' eingetragen."
        echo -e "${GREEN}Autostart erfolgreich in '$BASHRC_FILE' eingetragen.${NC}"
        echo -e "${YELLOW}Das Skript wird beim nächsten Start von Termux automatisch ausgeführt.${NC}"
        sleep 3
    fi
}

# --- Update-Funktion ---
update_script() {
    echo -e "${CYAN}${BOLD}🔄 Skript aktualisieren${NC}"
    log_message "INFO" "Starte Skript-Update von '$REPO_URL'."

    # Prüfe, ob das Skript in einem Git-Repository liegt
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
        # Kein Git-Repository, lade die Datei direkt herunter
        if ! check_command "wget" "wget"; then read -p "Weiter..."; return; fi
        echo -e "${CYAN}Kein Git-Repository. Lade Skript von '$RAW_SCRIPT_URL'...${NC}"
        temp_file="$HOME/startup.sh.tmp"
        if wget -O "$temp_file" "$RAW_SCRIPT_URL" 2>> "$LOG_FILE"; then
            # Prüfe, ob die heruntergeladene Datei gültig ist (z. B. enthält sie #!/bin/bash)
            if grep -q "^#!/bin/bash" "$temp_file"; then
                # Erstelle ein Backup des aktuellen Skripts
                backup_file="$SCRIPT_PATH.bak"
                mv "$SCRIPT_PATH" "$backup_file" 2>> "$LOG_FILE" && {
                    log_message "INFO" "Backup des aktuellen Skripts erstellt: $backup_file"
                }
                # Ersetze das Skript
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
    echo -e "${BLUE}${BOLD}=========================================${NC}"
    echo -e "${CYAN}${BOLD}      🚀 Willkommen bei Termux! 🚀       ${NC}"
    echo -e "${MAGENTA}${BOLD}=========================================${NC}"
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
                echo -e-d0e "${RED}Installation von '$pkg' fehlgeschlagen.${NC}"
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

    # Liste der Python-Standardmodule
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

# Funktion zum Starten eines Python-Skripts
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
    i=1; for script in "${py_scripts[@]}"; do echo -e " ${MAGENTA}$i)${NC} $script"; ((i++)); done; echo ""

    read -p "$(echo -e "${BLUE}Wähle Skript [Nummer]: ${NC}")" script_choice
    if ! [[ "$script_choice" =~ ^[0-9]+$ ]] || [ "$script_choice" -lt 1 ] || [ "$script_choice" -gt ${#py_scripts[@]} ]; then
        log_message "ERROR" "Ungültige Skriptauswahl: $script_choice"
        echo -e "${RED}Ungültige Auswahl.${NC}"; read -p "Weiter..."; return
    fi

    selected_script_index=$((script_choice - 1))
    script_to_run="${PYTHON_SCRIPT_DIR}/${py_scripts[$selected_script_index]}"

    echo -e "${CYAN}Führe aus: '${py_scripts[$selected_script_index]}'...${NC}"
    log_message "INFO" "Führe Skript '${py_scripts[$selected_script_index]}' aus."
    echo "--- Skript-Ausgabe Start ---"
    cd "$(dirname "$script_to_run")" && "$PYTHON_CMD" "$(basename "$script_to_run")" && cd "$HOME"
    echo "--- Skript-Ausgabe Ende ---"
    log_message "INFO" "Skriptausführung beendet: '${py_scripts[$selected_script_index]}'."
    echo -e "${GREEN}Skriptausführung beendet.${NC}"
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

# Funktion für Netzwerk-Scan
network_scan() {
    echo -e "${CYAN}${BOLD}📡 Netzwerk Scan (nmap Ping Scan)${NC}"
    log_message "INFO" "Starte Netzwerk-Scan."
    if ! check_command "nmap" "nmap"; then read -p "Weiter..."; return; fi

    local_ip=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null || ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    default_target=""
    if [ -n "$local_ip" ]; then
        subnet=$(echo "$local_ip" | cut -d. -f1-3).0/24
        default_target="$subnet"
        echo -e "${BLUE}Lokales Subnetz erkannt: $subnet ${NC}"
    fi

    read -p "$(echo -e "${BLUE}Ziel-IP/Subnetz [Standard: $default_target]: ${NC}")" target
    [ -z "$target" ] && target="$default_target"

    if [ -z "$target" ]; then
        log_message "ERROR" "Kein Ziel für Netzwerk-Scan angegeben."
        echo -e "${RED}Kein Ziel angegeben/gefunden.${NC}"; read -p "Weiter..."; return
    fi

    echo -e "${CYAN}Starte Ping Scan für '$target'... (Kann dauern)${NC}"
    nmap -sn "$target"
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

# Funktion zum Anzeigen des Menüs
show_menu() {
    echo -e "${YELLOW}${BOLD}${UNDERLINE}Hauptmenü:${NC}"
    echo -e " ${CYAN} 1) 🔄 Update System ${NC}(pkg)"
    echo -e " ${CYAN} 2) 📁 Dateimanager ${NC}(mc)"
    echo -e " ${CYAN} 3) 📊 Prozesse ${NC}(htop)"
    echo -e " ${CYAN} 4) 🌐 Netzwerk Info ${NC}(ifconfig)"
    echo -e " ${CYAN} 5) 📦 Paket installieren ${NC}(pkg)"
    echo -e " ${GREEN} 6) 🐍⚙️ Py-Module Auto-Install${NC}"
    echo -e " ${GREEN} 7) ▶️🐍 Python Skript starten${NC}"
    echo -e " ${GREEN} 8) 🛠️🐍 Py-Module Manuell ${NC}(pip)"
    echo -e " ${GREEN} 9) 🗑️🐍 Py-Module Deinstallieren ${NC}(pip)"
    echo -e " ${BLUE}10) 🐙 Git Helfer ${NC}(status/pull/commit/push)"
    echo -e " ${BLUE}11) 📡 Netzwerk Scan ${NC}(nmap)"
    echo -e " ${BLUE}12) 📝 .bashrc bearbeiten ${NC}(nano)"
    echo -e " ${BLUE}13) 💾 Termux Backup ${NC}(tar)"
    echo -e " ${BLUE}14) 🔒 SSH-Server Verwaltung ${NC}(sshd)"
    echo -e " ${BLUE}15) 🔄 Skript aktualisieren ${NC}(github)"
    echo -e " ${RED}16) 🚪 Beenden${NC}"
    echo ""
}

# --- Hauptlogik ---

# Lade Konfiguration
load_config

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

    read -p "$(echo -e "${WHITE}${BOLD}Wähle eine Option [1-16]: ${NC}")" choice

    case $choice in
        1) run_with_progress "pkg update && pkg upgrade -y"; read -p "Weiter...";;
        2) echo -e "${CYAN}🚀 Starte Dateimanager...${NC}"; if check_command "mc" "mc"; then mc; else read -p "Weiter..."; fi;;
        3) echo -e "${CYAN}🚀 Starte Prozessliste...${NC}"; if check_command "htop" "htop"; then htop; else read -p "Weiter..."; fi;;
        4) echo -e "${CYAN}🔎 Zeige Netzwerk Info...${NC}"; if check_command "ifconfig" "net-tools"; then ifconfig; else read -p "Weiter..."; fi; read -p "Weiter...";;
        5) read -p "$(echo -e "${BLUE}Zu installierende pkg-Pakete: ${NC}")" packages; if [ -n "$packages" ]; then echo -e "${CYAN}Installiere: $packages...${NC}"; pkg install $packages -y 2>> "$LOG_FILE"; else echo -e "${YELLOW}Keine Pakete angegeben.${NC}"; fi; read -p "Weiter...";;
        6) auto_install_python_modules;;
        7) start_python_script;;
        8) manual_install_python_modules;;
        9) uninstall_python_modules;;
        10) git_helper;;
        11) network_scan;;
        12) edit_bashrc;;
        13) backup_termux;;
        14) manage_ssh;;
        15) update_script;;
        16) echo -e "${GREEN}👋 Auf Wiedersehen!${NC}"; log_message "INFO" "Skript beendet."; unset TERMUX_SCRIPT_STARTUP_RUNNING; exit 0;;
        *) log_message "ERROR" "Ungültige Menüauswahl: $choice"; echo -e "${RED}🚨 Ungültige Auswahl.${NC}"; sleep 2;;
    esac
done
