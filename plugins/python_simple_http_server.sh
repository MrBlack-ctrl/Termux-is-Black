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

    echo -e "${BOLD}${color}[PY_HTTP_SERVER] ${type}:${NC} $message"
}

# Main function for the Python Simple HTTP Server plugin
run_python_simple_http_server() {
    echo -e "${BOLD}${CYAN}=============================================${NC}"
    echo -e "${BOLD}${CYAN}=== Python Simple HTTP Server v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}=============================================${NC}"
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

    # Check if http.server module is available
    if ! $PYTHON_CMD -m http.server --help &> /dev/null; then
        log_message ERROR "The 'http.server' module is not available for '$PYTHON_CMD'."
        log_message ERROR "For Python 2, you might try 'python -m SimpleHTTPServer'."
        log_message ERROR "Please ensure your Python installation is correct and includes the http module."
        read -p "Weiter..."
        return 1
    fi

    local serve_dir
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter directory to serve (default: $PWD):${NC} ")" serve_dir
    serve_dir="${serve_dir:-$PWD}" # Default to current directory if empty

    if [ ! -d "$serve_dir" ]; then
        log_message ERROR "Directory '$serve_dir' not found or is not a directory."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Selected directory to serve: '$serve_dir'"

    local port_number
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter port number (default: 8000):${NC} ")" port_number
    port_number="${port_number:-8000}"

    # Validate port number (basic check: is it a number?)
    if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
        log_message ERROR "Invalid port number: '$port_number'. Must be a number."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Selected port: '$port_number'"

    log_message INFO "Attempting to start HTTP server in '$serve_dir' on port '$port_number'..."
    echo -e "${BOLD}${YELLOW}To stop the server, press Ctrl+C.${NC}"

    local original_dir="$PWD"
    if cd "$serve_dir"; then
        log_message INFO "Changed directory to '$serve_dir'."
        # Execute the Python HTTP server
        if $PYTHON_CMD -m http.server "$port_number"; then
            # This block will likely not be reached if server starts successfully and is stopped by Ctrl+C
            # as Ctrl+C terminates the python process and the script might terminate too depending on shell options.
            # However, if http.server exits by itself for some reason (e.g. port already in use and it handles that gracefully)
            log_message INFO "HTTP server process finished."
        else
            # This block is reached if the python command itself fails immediately (e.g., module not found, invalid args prior to server start)
            log_message ERROR "Failed to start HTTP server. '$PYTHON_CMD -m http.server $port_number' command failed."
        fi

        log_message INFO "Returning to original directory: '$original_dir'."
        if cd "$original_dir"; then
            log_message INFO "Successfully returned to '$original_dir'."
        else
            log_message ERROR "Failed to return to original directory '$original_dir'."
        fi
    else
        log_message ERROR "Failed to change directory to '$serve_dir'."
    fi
    # The main script's "Weiter..." prompt will appear after this function returns.
    # If Ctrl+C stops the server, it also stops this script at the point of the server command,
    # so the cd back might not always execute if the script itself is terminated.
    # However, if the server command exits cleanly or fails, the cd back will be attempted.
}

log_message INFO "Plugin loaded (Version: ${PLUGIN_VERSION})"
