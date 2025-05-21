#!/bin/bash

# Standard color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PLUGIN_VERSION="1.0.0"

# Function to log messages
log_message() {
    local type="$1"
    local message="$2"
    local color="$NC"

    case "$type" in
        INFO) color="$GREEN" ;;
        WARNING) color="$YELLOW" ;;
        ERROR) color="$RED" ;;
        DEBUG) color="$BLUE" ;;
        *) message="[UNKNOWN TYPE] $message" ;;
    esac

    echo -e "${BOLD}${color}[PY_REQS_HELPER] ${type}:${NC} $message"
}

# Main function for the Python Requirements Helper plugin
run_python_requirements_helper() {
    echo -e "${BOLD}${CYAN}===========================================${NC}"
    echo -e "${BOLD}${CYAN}=== Python Requirements Helper v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}===========================================${NC}"
    echo # Newline for better readability

    # Load PYTHON_CMD from config or default to python3
    PYTHON_CMD="python3"
    if [ -f "$HOME/.termux_startup.conf" ]; then
        CONFIG_PYTHON_CMD=$( (source "$HOME/.termux_startup.conf" && echo "$PYTHON_CMD") )
        if [ -n "$CONFIG_PYTHON_CMD" ]; then
            PYTHON_CMD="$CONFIG_PYTHON_CMD"
            log_message INFO "Loaded PYTHON_CMD='$PYTHON_CMD' from $HOME/.termux_startup.conf"
        else
            log_message INFO "PYTHON_CMD not found in $HOME/.termux_startup.conf, using default '$PYTHON_CMD'."
        fi
    else
        log_message INFO "$HOME/.termux_startup.conf not found, using default PYTHON_CMD='$PYTHON_CMD'."
    fi

    # Check if pip is available
    if ! $PYTHON_CMD -m pip --version &> /dev/null; then
        log_message ERROR "pip is not available for '$PYTHON_CMD'. Please install it (e.g., apt install python3-pip or ensure your Python environment has pip)."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "pip found for '$PYTHON_CMD'."

    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. Generate 'requirements.txt' from current environment"
        echo "  2. Install packages from 'requirements.txt'"
        echo "  3. Freeze environment to a specific project's 'requirements.txt'"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1, 2, 3, q]:${NC} ")" choice

        case "$choice" in
            1)
                # Generate 'requirements.txt' from current environment
                log_message INFO "Option 1: Generate 'requirements.txt' from current environment"
                if [ -n "$VIRTUAL_ENV" ]; then
                    log_message INFO "Virtual environment detected: $VIRTUAL_ENV"
                else
                    log_message WARNING "No active virtual environment detected. This will freeze global packages."
                    read -p "$(echo -e "  ${BOLD}${YELLOW}Are you sure you want to continue without an active virtual environment? (y/N):${NC} ")" confirm_global_freeze
                    if [[ ! "$confirm_global_freeze" =~ ^[Yy]$ ]]; then
                        log_message INFO "Operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi
                fi

                local output_path
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter output file path (default: $PWD/requirements.txt):${NC} ")" output_path
                output_path="${output_path:-$PWD/requirements.txt}"

                # Ensure the directory for the output path exists if a specific path is given
                local output_dir=$(dirname "$output_path")
                if [ ! -d "$output_dir" ]; then
                    log_message WARNING "Directory '$output_dir' does not exist. Attempting to create it."
                    mkdir -p "$output_dir"
                    if [ $? -ne 0 ]; then
                        log_message ERROR "Failed to create directory '$output_dir'. Cannot save requirements file."
                        read -p "Weiter..."
                        continue
                    fi
                fi

                log_message INFO "Generating requirements file at '$output_path'..."
                if $PYTHON_CMD -m pip freeze > "$output_path"; then
                    log_message INFO "Successfully generated '$output_path'."
                else
                    log_message ERROR "Failed to generate '$output_path'."
                fi
                read -p "Weiter..."
                ;;
            2)
                # Install packages from 'requirements.txt'
                log_message INFO "Option 2: Install packages from 'requirements.txt'"
                local req_file_path
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter path to requirements.txt file:${NC} ")" req_file_path

                if [ -z "$req_file_path" ]; then
                    log_message ERROR "Path to requirements.txt cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ ! -f "$req_file_path" ]; then
                    log_message ERROR "File '$req_file_path' not found."
                    read -p "Weiter..."
                    continue
                fi

                log_message INFO "Installing packages from '$req_file_path'..."
                if $PYTHON_CMD -m pip install -r "$req_file_path"; then
                    log_message INFO "Successfully installed packages from '$req_file_path'."
                else
                    log_message ERROR "Failed to install packages from '$req_file_path'. Check pip output for details."
                fi
                read -p "Weiter..."
                ;;
            3)
                # Freeze environment to a specific project's 'requirements.txt'
                log_message INFO "Option 3: Freeze environment to a specific project's 'requirements.txt'"
                if [ -n "$VIRTUAL_ENV" ]; then
                    log_message INFO "Virtual environment detected: $VIRTUAL_ENV"
                else
                    log_message WARNING "No active virtual environment detected. This will freeze global packages."
                     read -p "$(echo -e "  ${BOLD}${YELLOW}Are you sure you want to continue without an active virtual environment? (y/N):${NC} ")" confirm_global_freeze
                    if [[ ! "$confirm_global_freeze" =~ ^[Yy]$ ]]; then
                        log_message INFO "Operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi
                fi

                local project_dir_path
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter project directory path:${NC} ")" project_dir_path

                if [ -z "$project_dir_path" ]; then
                    log_message ERROR "Project directory path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ ! -d "$project_dir_path" ]; then
                    log_message ERROR "Project directory '$project_dir_path' not found or is not a directory."
                    read -p "Weiter..."
                    continue
                fi

                local target_req_file="$project_dir_path/requirements.txt"
                log_message INFO "Generating requirements file at '$target_req_file'..."

                if $PYTHON_CMD -m pip freeze > "$target_req_file"; then
                    log_message INFO "Successfully generated '$target_req_file'."
                else
                    log_message ERROR "Failed to generate '$target_req_file'."
                fi
                read -p "Weiter..."
                ;;
            q|Q)
                log_message INFO "Exiting Python Requirements Helper."
                break
                ;;
            *)
                log_message ERROR "Invalid choice. Please try again."
                read -p "Weiter..."
                ;;
        esac
    done
}

log_message INFO "Plugin loaded (Version: ${PLUGIN_VERSION})"
