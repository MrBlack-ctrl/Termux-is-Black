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

    echo -e "${BOLD}${color}[PY_FORMAT_LINT] ${type}:${NC} $message"
}

# Main function for the Python Code Formatter/Linter plugin
run_python_code_formatter_linter() {
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${CYAN}=== Python Code Formatter/Linter v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
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

    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. Format code"
        echo "  2. Lint code"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1, 2, q]:${NC} ")" choice

        case "$choice" in
            1)
                # Format code logic
                local formatter_choice
                echo -e "\n  ${BOLD}${CYAN}Choose a formatter:${NC}"
                echo "    b. black"
                echo "    y. yapf"
                echo "    q. Back to main menu"
                read -p "$(echo -e "  ${BOLD}${CYAN}Enter your choice [b, y, q]:${NC} ")" formatter_choice

                local formatter_cmd=""
                local formatter_name=""

                case "$formatter_choice" in
                    b|B)
                        formatter_name="black"
                        formatter_cmd="black"
                        ;;
                    y|Y)
                        formatter_name="yapf"
                        formatter_cmd="yapf -i" # yapf needs -i for in-place formatting
                        ;;
                    q|Q)
                        continue # Go back to the main menu
                        ;;
                    *)
                        log_message ERROR "Invalid formatter choice."
                        read -p "Weiter..."
                        continue # Go back to the main menu
                        ;;
                esac

                if ! command -v $formatter_name &> /dev/null; then
                    log_message ERROR "$formatter_name is not installed. Please install it using: ${BOLD}$PYTHON_CMD -m pip install $formatter_name${NC}"
                    read -p "Weiter..."
                    continue # Go back to the main menu
                fi

                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter target file or directory path to format:${NC} ")" format_path
                if [ -z "$format_path" ]; then
                    log_message ERROR "Path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ ! -e "$format_path" ]; then # Check if path exists (file or directory)
                    log_message ERROR "Path '$format_path' does not exist."
                    read -p "Weiter..."
                    continue
                fi

                log_message INFO "Formatting '$format_path' with $formatter_name..."
                if [ "$formatter_name" = "yapf" ]; then
                    if $PYTHON_CMD -m yapf -i "$format_path"; then # Use python -m for consistency
                        log_message INFO "Successfully formatted '$format_path' with yapf."
                    else
                        log_message ERROR "Error formatting '$format_path' with yapf."
                    fi
                elif [ "$formatter_name" = "black" ]; then
                     if $PYTHON_CMD -m black "$format_path"; then # Use python -m for consistency
                        log_message INFO "Successfully formatted '$format_path' with black."
                    else
                        log_message ERROR "Error formatting '$format_path' with black."
                    fi
                else
                     log_message ERROR "Unknown formatter '$formatter_name' selected for execution." # Should not happen
                fi
                read -p "Weiter..."
                ;;
            2)
                # Lint code logic
                local linter_name="pylint"
                if ! command -v $linter_name &> /dev/null; then
                     # Try checking with python -m as well, as it might be installed as a module
                    if ! $PYTHON_CMD -m $linter_name --version &> /dev/null; then
                        log_message ERROR "$linter_name is not installed. Please install it using: ${BOLD}$PYTHON_CMD -m pip install $linter_name${NC}"
                        read -p "Weiter..."
                        continue # Go back to the main menu
                    fi
                     log_message INFO "$linter_name found via '$PYTHON_CMD -m $linter_name'."
                fi

                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter target file or directory path to lint:${NC} ")" lint_path
                if [ -z "$lint_path" ]; then
                    log_message ERROR "Path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ ! -e "$lint_path" ]; then # Check if path exists (file or directory)
                    log_message ERROR "Path '$lint_path' does not exist."
                    read -p "Weiter..."
                    continue
                fi

                log_message INFO "Linting '$lint_path' with $linter_name..."
                echo -e "${CYAN}--- Pylint Output Start ---${NC}"
                # Pylint can have a lot of output, so just run it directly.
                # Using $PYTHON_CMD -m pylint ensures we use the one associated with the selected python interpreter
                if $PYTHON_CMD -m $linter_name "$lint_path"; then
                    log_message INFO "Pylint finished successfully for '$lint_path'."
                else
                    # Pylint exits with a bitmask of error codes. Any non-zero exit is usually an issue found.
                    log_message WARNING "Pylint finished for '$lint_path' and reported issues (see output above)."
                fi
                echo -e "${CYAN}--- Pylint Output End ---${NC}"
                read -p "Weiter..."
                ;;
            q|Q)
                log_message INFO "Exiting Python Code Formatter/Linter."
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
