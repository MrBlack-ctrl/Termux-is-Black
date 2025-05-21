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

    echo -e "${BOLD}${color}[CLIPBOARD_HELPER] ${type}:${NC} $message"
}

# Main function for the Clipboard Helper plugin
run_clipboard_helper() {
    echo -e "${BOLD}${CYAN}==================================${NC}"
    echo -e "${BOLD}${CYAN}=== Clipboard Helper v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}==================================${NC}"
    echo # Newline for better readability

    # Check for termux-api commands
    if ! command -v termux-clipboard-get &> /dev/null || ! command -v termux-clipboard-set &> /dev/null; then
        log_message ERROR "termux-clipboard-get or termux-clipboard-set not found."
        echo -e "${YELLOW}Please ensure the 'termux-api' package is installed.${NC}"
        echo -e "${YELLOW}Run: ${GREEN}pkg install termux-api${NC}"
        echo -e "${YELLOW}Also, ensure the Termux:API app is installed and functioning (available from F-Droid).${NC}"
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Termux clipboard commands found."

    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. View clipboard content"
        echo "  2. Set clipboard from text input"
        echo "  3. Set clipboard from file content"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1, 2, 3, q]:${NC} ")" choice

        case "$choice" in
            1) # View clipboard content
                log_message INFO "Option 1: View clipboard content"
                local clipboard_content
                clipboard_content=$(termux-clipboard-get)
                if [ $? -eq 0 ]; then
                    if [ -n "$clipboard_content" ]; then
                        log_message INFO "Current clipboard content:"
                        echo -e "${GREEN}-------------------- CLIPBOARD START --------------------${NC}"
                        echo "$clipboard_content"
                        echo -e "${GREEN}--------------------- CLIPBOARD END ---------------------${NC}"
                    else
                        log_message INFO "Clipboard is empty."
                    fi
                else
                    log_message ERROR "Failed to get clipboard content."
                    echo -e "${YELLOW}Ensure Termux:API app is running and has clipboard permissions.${NC}"
                fi
                read -p "Weiter..."
                ;;
            2) # Set clipboard from text input
                log_message INFO "Option 2: Set clipboard from text input"
                local text_to_set
                # Using read -e for basic readline editing capabilities
                read -e -p "$(echo -e "  ${BOLD}${MAGENTA}Enter text to set to clipboard (Ctrl+D to finish if multi-line, or just Enter):${NC}\n")${GREEN}" text_to_set
                echo -e "${NC}" # Reset color after input

                if termux-clipboard-set "$text_to_set"; then
                    log_message INFO "Clipboard content set successfully."
                    if [ ${#text_to_set} -gt 50 ]; then # Show a snippet if long
                        log_message DEBUG "Set: \"$(echo "$text_to_set" | head -c 50)...\""
                    else
                        log_message DEBUG "Set: \"$text_to_set\""
                    fi
                else
                    log_message ERROR "Failed to set clipboard content."
                     echo -e "${YELLOW}Ensure Termux:API app is running and has clipboard permissions.${NC}"
                fi
                read -p "Weiter..."
                ;;
            3) # Set clipboard from file content
                log_message INFO "Option 3: Set clipboard from file content"
                local file_path
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter file path to copy content from:${NC} ")" file_path

                if [ -z "$file_path" ]; then
                    log_message ERROR "File path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi

                # Expand tilde, etc.
                local expanded_file_path
                eval "expanded_file_path=\"$file_path\""

                if [ ! -f "$expanded_file_path" ] || [ ! -r "$expanded_file_path" ]; then
                    log_message ERROR "File '$expanded_file_path' not found or is not readable."
                    read -p "Weiter..."
                    continue
                fi

                # Check file size - termux-clipboard-set might have limits or performance issues with huge files
                local file_size_bytes=$(wc -c < "$expanded_file_path")
                local max_size_bytes=1000000 # 1MB as a arbitrary limit
                if [ "$file_size_bytes" -gt "$max_size_bytes" ]; then
                    log_message WARNING "File size ($file_size_bytes bytes) is large. Proceeding, but it might be slow or fail."
                    read -p "$(echo -e "  ${BOLD}${YELLOW}Are you sure you want to continue? (y/N):${NC} ")" confirm_large_file
                    if [[ ! "$confirm_large_file" =~ ^[Yy]$ ]]; then
                        log_message INFO "Operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi
                fi

                if termux-clipboard-set < "$expanded_file_path"; then
                    log_message INFO "Clipboard content set successfully from file '$expanded_file_path'."
                else
                    log_message ERROR "Failed to set clipboard content from file '$expanded_file_path'."
                    echo -e "${YELLOW}Ensure Termux:API app is running and has clipboard permissions.${NC}"
                fi
                read -p "Weiter..."
                ;;
            q|Q)
                log_message INFO "Exiting Clipboard Helper."
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
