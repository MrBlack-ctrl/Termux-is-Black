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

    echo -e "${BOLD}${color}[TEXT_TOOLKIT] ${type}:${NC} $message"
}

# Main function for the Text Manipulation Toolkit plugin
run_text_manipulation_toolkit() {
    echo -e "${BOLD}${CYAN}=======================================${NC}"
    echo -e "${BOLD}${CYAN}=== Text Manipulation Toolkit v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}=======================================${NC}"
    echo # Newline for better readability

    # Load PYTHON_CMD from config or default to python3
    PYTHON_CMD="python3"
    local python_available=true
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

    if ! command -v $PYTHON_CMD &> /dev/null; then
        log_message WARNING "Python command '$PYTHON_CMD' not found. URL Encode/Decode will be unavailable."
        python_available=false
    else
        log_message INFO "Python command '$PYTHON_CMD' found."
    fi


    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. Base64 Encode (string)"
        echo "  2. Base64 Decode (string)"
        echo "  3. URL Encode (string)"
        echo "  4. URL Decode (string)"
        echo "  5. Count lines/words/characters in a file"
        echo "  6. Convert file content to UPPERCASE"
        echo "  7. Convert file content to lowercase"
        echo "  8. Find & Replace in file"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1-8, q]:${NC} ")" choice

        case "$choice" in
            1) # Base64 Encode
                log_message INFO "Option 1: Base64 Encode"
                local input_string
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter string to encode:${NC} ")" input_string
                if [ -z "$input_string" ]; then
                    log_message WARNING "Input string is empty."
                fi
                local encoded_string=$(echo -n "$input_string" | base64)
                log_message INFO "Encoded string:"
                echo -e "${GREEN}$encoded_string${NC}"
                read -p "Weiter..."
                ;;
            2) # Base64 Decode
                log_message INFO "Option 2: Base64 Decode"
                local input_string
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter Base64 string to decode:${NC} ")" input_string
                if [ -z "$input_string" ]; then
                    log_message WARNING "Input string is empty. Decoding an empty string results in an empty string."
                fi
                # Validate if it's a valid base64 string? For simplicity, skipping direct validation.
                # base64 -d will often return non-zero for invalid input, but not always clearly.
                local decoded_string
                decoded_string=$(echo "$input_string" | base64 -d 2>/dev/null)
                if [ $? -eq 0 ]; then
                    log_message INFO "Decoded string:"
                    echo -e "${GREEN}$decoded_string${NC}"
                else
                    log_message ERROR "Failed to decode Base64 string. It might be invalid."
                    log_message DEBUG "Attempted to decode: '$input_string'"
                fi
                read -p "Weiter..."
                ;;
            3) # URL Encode
                if ! $python_available; then
                    log_message ERROR "Python ('$PYTHON_CMD') is not available. Cannot perform URL encoding."
                    read -p "Weiter..."
                    continue
                fi
                log_message INFO "Option 3: URL Encode"
                local input_string
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter string to URL encode:${NC} ")" input_string
                if [ -z "$input_string" ]; then
                    log_message WARNING "Input string is empty."
                fi
                # Using Python for URL encoding
                local encoded_string
                encoded_string=$($PYTHON_CMD -c "import urllib.parse; print(urllib.parse.quote('''$input_string'''))" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    log_message INFO "URL Encoded string:"
                    echo -e "${GREEN}$encoded_string${NC}"
                else
                    log_message ERROR "Failed to URL encode string using $PYTHON_CMD."
                    log_message DEBUG "Python command executed: $PYTHON_CMD -c \"import urllib.parse; print(urllib.parse.quote('''$input_string'''))\""
                fi
                read -p "Weiter..."
                ;;
            4) # URL Decode
                if ! $python_available; then
                    log_message ERROR "Python ('$PYTHON_CMD') is not available. Cannot perform URL decoding."
                    read -p "Weiter..."
                    continue
                fi
                log_message INFO "Option 4: URL Decode"
                local input_string
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter URL string to decode:${NC} ")" input_string
                if [ -z "$input_string" ]; then
                    log_message WARNING "Input string is empty."
                fi
                # Using Python for URL decoding
                local decoded_string
                decoded_string=$($PYTHON_CMD -c "import urllib.parse; print(urllib.parse.unquote('''$input_string'''))" 2>/dev/null)

                if [ $? -eq 0 ]; then
                    log_message INFO "URL Decoded string:"
                    echo -e "${GREEN}$decoded_string${NC}"
                else
                    log_message ERROR "Failed to URL decode string using $PYTHON_CMD."
                    log_message DEBUG "Python command executed: $PYTHON_CMD -c \"import urllib.parse; print(urllib.parse.unquote('''$input_string'''))\""
                fi
                read -p "Weiter..."
                ;;
            5) # Count lines/words/characters in a file
                log_message INFO "Option 5: Count lines/words/characters in a file"
                local file_path
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter file path:${NC} ")" file_path

                if [ -z "$file_path" ]; then
                    log_message ERROR "File path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ ! -f "$file_path" ] || [ ! -r "$file_path" ]; then
                    log_message ERROR "File '$file_path' not found or is not readable."
                    read -p "Weiter..."
                    continue
                fi

                local lines=$(wc -l < "$file_path" | awk '{print $1}')
                local words=$(wc -w < "$file_path" | awk '{print $1}')
                local chars=$(wc -c < "$file_path" | awk '{print $1}') # wc -m for characters, wc -c for bytes. Using -c for consistency.

                log_message INFO "File: '$file_path'"
                echo -e "  Lines:      ${GREEN}$lines${NC}"
                echo -e "  Words:      ${GREEN}$words${NC}"
                echo -e "  Characters: ${GREEN}$chars${NC} (bytes)"
                read -p "Weiter..."
                ;;
            6) # Convert file content to UPPERCASE
                log_message INFO "Option 6: Convert file content to UPPERCASE"
                local input_file output_file
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter input file path:${NC} ")" input_file
                if [ ! -f "$input_file" ] || [ ! -r "$input_file" ]; then
                    log_message ERROR "Input file '$input_file' not found or not readable."
                    read -p "Weiter..."
                    continue
                fi
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter output file path:${NC} ")" output_file
                if [ -z "$output_file" ]; then
                    log_message ERROR "Output file path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ -f "$output_file" ]; then
                    read -p "$(echo -e "  ${BOLD}${YELLOW}Output file '$output_file' exists. Overwrite? (y/N):${NC} ")" confirm_overwrite
                    if [[ ! "$confirm_overwrite" =~ ^[Yy]$ ]]; then
                        log_message INFO "Operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi
                fi
                if tr '[:lower:]' '[:upper:]' < "$input_file" > "$output_file"; then
                    log_message INFO "File content converted to UPPERCASE. Output saved to '$output_file'."
                else
                    log_message ERROR "Failed to convert file content to UPPERCASE."
                fi
                read -p "Weiter..."
                ;;
            7) # Convert file content to lowercase
                log_message INFO "Option 7: Convert file content to lowercase"
                local input_file output_file
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter input file path:${NC} ")" input_file
                if [ ! -f "$input_file" ] || [ ! -r "$input_file" ]; then
                    log_message ERROR "Input file '$input_file' not found or not readable."
                    read -p "Weiter..."
                    continue
                fi
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter output file path:${NC} ")" output_file
                 if [ -z "$output_file" ]; then
                    log_message ERROR "Output file path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ -f "$output_file" ]; then
                    read -p "$(echo -e "  ${BOLD}${YELLOW}Output file '$output_file' exists. Overwrite? (y/N):${NC} ")" confirm_overwrite
                    if [[ ! "$confirm_overwrite" =~ ^[Yy]$ ]]; then
                        log_message INFO "Operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi
                fi
                if tr '[:upper:]' '[:lower:]' < "$input_file" > "$output_file"; then
                    log_message INFO "File content converted to lowercase. Output saved to '$output_file'."
                else
                    log_message ERROR "Failed to convert file content to lowercase."
                fi
                read -p "Weiter..."
                ;;
            8) # Find & Replace in file
                log_message INFO "Option 8: Find & Replace in file"
                local input_file output_file find_str replace_str
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter input file path:${NC} ")" input_file
                if [ ! -f "$input_file" ] || [ ! -r "$input_file" ]; then
                    log_message ERROR "Input file '$input_file' not found or not readable."
                    read -p "Weiter..."
                    continue
                fi
                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter output file path:${NC} ")" output_file
                if [ -z "$output_file" ]; then
                    log_message ERROR "Output file path cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                if [ -f "$output_file" ] && [ "$input_file" != "$output_file" ]; then # Allow same file for in-place, sed -i handles it
                    read -p "$(echo -e "  ${BOLD}${YELLOW}Output file '$output_file' exists. Overwrite? (y/N):${NC} ")" confirm_overwrite
                    if [[ ! "$confirm_overwrite" =~ ^[Yy]$ ]]; then
                        log_message INFO "Operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi
                fi

                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter string to find:${NC} ")" find_str
                if [ -z "$find_str" ]; then # Finding empty string can have weird sed behavior, disallow for simplicity
                    log_message ERROR "Find string cannot be empty."
                    read -p "Weiter..."
                    continue
                fi
                # Escape special characters for sed 's/FIND/REPLACE/g' command
                # Basic escaping for / & \. More robust escaping is complex.
                local escaped_find_str=$(echo "$find_str" | sed -e 's/[\/&]/\\&/g')

                read -p "$(echo -e "  ${BOLD}${MAGENTA}Enter string to replace with:${NC} ")" replace_str
                local escaped_replace_str=$(echo "$replace_str" | sed -e 's/[\/&]/\\&/g')


                log_message INFO "Previewing changes (first 5 occurrences or lines with changes):"
                # Show lines that would change, highlighting the find_str if possible (grep --color)
                # This is a simplified preview. A true diff is harder with just sed preview.
                echo -e "${CYAN}--- Preview Start (lines that would change) ---${NC}"
                grep --color=always -E -m 5 "$escaped_find_str" "$input_file" || log_message INFO "No occurrences of '$find_str' found in preview."
                echo -e "${CYAN}--- Preview End ---${NC}"

                read -p "$(echo -e "  ${BOLD}${MAGENTA}Proceed with find & replace? (y/N):${NC} ")" confirm_replace
                if [[ "$confirm_replace" =~ ^[Yy]$ ]]; then
                    if [ "$input_file" == "$output_file" ]; then
                        # In-place editing
                        log_message INFO "Performing in-place replacement in '$input_file'..."
                        if sed -i "s/$escaped_find_str/$escaped_replace_str/g" "$input_file"; then
                            log_message INFO "Successfully replaced text in '$input_file'."
                        else
                            log_message ERROR "Failed to replace text in '$input_file'."
                        fi
                    else
                        # Replacing and writing to a new file
                        log_message INFO "Replacing text from '$input_file' and saving to '$output_file'..."
                        if sed "s/$escaped_find_str/$escaped_replace_str/g" "$input_file" > "$output_file"; then
                            log_message INFO "Successfully replaced text. Output saved to '$output_file'."
                        else
                            log_message ERROR "Failed to replace text or save to '$output_file'."
                        fi
                    fi
                else
                    log_message INFO "Find & Replace operation cancelled by user."
                fi
                read -p "Weiter..."
                ;;
            q|Q)
                log_message INFO "Exiting Text Manipulation Toolkit."
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
