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

    echo -e "${BOLD}${color}[PY_DOC_SEARCH] ${type}:${NC} $message"
}

# Main function for the Python Documentation Searcher plugin
run_python_doc_searcher() {
    echo -e "${BOLD}${CYAN}=============================================${NC}"
    echo -e "${BOLD}${CYAN}=== Python Documentation Searcher v${PLUGIN_VERSION} ===${NC}"
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

    # Check if pydoc module is available
    if ! $PYTHON_CMD -m pydoc -h &> /dev/null; then
        log_message ERROR "The 'pydoc' module is not available for '$PYTHON_CMD'."
        log_message ERROR "Please ensure your Python installation is correct and includes the pydoc module."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "'pydoc' module found for '$PYTHON_CMD'."

    local search_term
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter Python module, function, or class name to search for:${NC} ")" search_term

    if [ -z "$search_term" ]; then
        log_message ERROR "Search term cannot be empty."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Search term: '$search_term'"

    log_message INFO "Fetching documentation for '$search_term' using '$PYTHON_CMD -m pydoc'..."
    echo -e "${CYAN}--- pydoc output for '$search_term' ---${NC}"
    # pydoc handles its own paging if necessary
    if $PYTHON_CMD -m pydoc "$search_term"; then
        log_message INFO "pydoc executed successfully for '$search_term'."
    else
        log_message WARNING "pydoc returned an error or no documentation found for '$search_term'."
        # pydoc usually prints its own error messages to stderr, which will be visible.
    fi
    echo -e "${CYAN}--- End of pydoc output ---${NC}"
    echo # Add a blank line for readability before the next prompt

    local online_search_choice
    read -p "$(echo -e "${BOLD}${MAGENTA}Search for '$search_term' online? (y/N):${NC} ")" online_search_choice

    if [[ "$online_search_choice" =~ ^[Yy]$ ]]; then
        # URL encode the search term for safety, though simple terms might not need it.
        # Basic version: just use the term as is.
        # More robust: Python urlencode or similar. For bash, a simple sed replacement for spaces.
        local encoded_search_term=$(echo "$search_term" | sed 's/ /%20/g')

        # Using docs.python.org search is generally reliable.
        local search_url="https://docs.python.org/3/search.html?q=${encoded_search_term}"

        log_message INFO "Generated online search URL: $search_url"
        echo -e "${GREEN}You can open this URL in your browser.${NC}"
        echo -e "${YELLOW}In Termux, you can try using: termux-open-url \"$search_url\"${NC}"
    else
        log_message INFO "Skipping online search."
    fi

    read -p "Weiter..."
}

log_message INFO "Plugin loaded (Version: ${PLUGIN_VERSION})"
