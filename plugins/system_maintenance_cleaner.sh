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

    echo -e "${BOLD}${color}[SYS_MAINTENANCE] ${type}:${NC} $message"
}

# Main function for the System Maintenance Cleaner plugin
run_system_maintenance_cleaner() {
    echo -e "${BOLD}${CYAN}===========================================${NC}"
    echo -e "${BOLD}${CYAN}=== System Maintenance Cleaner v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}===========================================${NC}"
    echo # Newline for better readability

    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. Clear apt cache"
        echo "  2. Trim termux_startup.log"
        echo "  3. Find & delete empty directories under $HOME"
        echo "  4. Find large files under $HOME (>50MB)"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1, 2, 3, 4, q]:${NC} ")" choice

        case "$choice" in
            1)
                # Clear apt cache
                log_message INFO "Option 1: Clear apt cache"
                echo -e "${YELLOW}This will run 'apt-get clean' to free up disk space.${NC}"
                read -p "$(echo -e "${BOLD}${MAGENTA}Are you sure you want to continue? (y/N):${NC} ")" confirm_apt_clean
                if [[ "$confirm_apt_clean" =~ ^[Yy]$ ]]; then
                    log_message INFO "Running 'apt-get clean'..."
                    if apt-get clean; then
                        log_message INFO "'apt-get clean' completed successfully."
                    else
                        log_message ERROR "Failed to run 'apt-get clean'. Exit code: $?"
                        log_message ERROR "You might need to run 'apt update' first or have other apt issues."
                    fi
                else
                    log_message INFO "Apt cache clear operation cancelled by user."
                fi
                read -p "Weiter..."
                ;;
            2)
                # Trim termux_startup.log
                log_message INFO "Option 2: Trim termux_startup.log"
                local log_file="$HOME/termux_startup.log"
                local lines_to_keep=500
                if [ -f "$log_file" ]; then
                    local current_lines=$(wc -l < "$log_file")
                    log_message INFO "Log file '$log_file' found with $current_lines lines."
                    if [ "$current_lines" -le "$lines_to_keep" ]; then
                        log_message INFO "Log file is already within the desired size ($lines_to_keep lines). No action needed."
                    else
                        echo -e "${YELLOW}This will trim '$log_file' to the last $lines_to_keep lines.${NC}"
                        read -p "$(echo -e "${BOLD}${MAGENTA}Are you sure you want to continue? (y/N):${NC} ")" confirm_trim_log
                        if [[ "$confirm_trim_log" =~ ^[Yy]$ ]]; then
                            log_message INFO "Trimming '$log_file' to last $lines_to_keep lines..."
                            if tail -n "$lines_to_keep" "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"; then
                                log_message INFO "Successfully trimmed '$log_file'."
                            else
                                log_message ERROR "Failed to trim '$log_file'."
                                rm -f "$log_file.tmp" # Clean up temp file if mv failed
                            fi
                        else
                            log_message INFO "Log trim operation cancelled by user."
                        fi
                    fi
                else
                    log_message WARNING "Log file '$log_file' not found. Nothing to trim."
                fi
                read -p "Weiter..."
                ;;
            3)
                # Find & delete empty directories under $HOME
                log_message INFO "Option 3: Find & delete empty directories under $HOME"
                echo -e "${YELLOW}Searching for empty directories under $HOME...${NC}"
                # Use an array to store found directories
                local empty_dirs=()
                # Read directory names into the array, handling spaces and newlines in names
                while IFS= read -r -d $'\0' dir; do
                    empty_dirs+=("$dir")
                done < <(find "$HOME" -mindepth 1 -type d -empty -print0) # -mindepth 1 to exclude $HOME itself if empty

                if [ ${#empty_dirs[@]} -eq 0 ]; then
                    log_message INFO "No empty directories found under $HOME."
                else
                    log_message INFO "Found the following empty directories:"
                    for dir in "${empty_dirs[@]}"; do
                        echo "  - $dir"
                    done
                    echo # Newline for readability

                    read -p "$(echo -e "${BOLD}${MAGENTA}Delete all listed empty directories? (y/N):${NC} ")" confirm_delete_empty
                    if [[ "$confirm_delete_empty" =~ ^[Yy]$ ]]; then
                        log_message INFO "Deleting all listed empty directories..."
                        # Use the stored list for deletion to avoid re-running find and potentially missing some
                        # or finding new ones created in the meantime.
                        local delete_count=0
                        local error_count=0
                        for dir in "${empty_dirs[@]}"; do
                            if rmdir "$dir"; then # rmdir is safer as it only removes empty dirs
                                log_message INFO "Deleted: $dir"
                                ((delete_count++))
                            else
                                log_message ERROR "Failed to delete: $dir (might not be empty or permission issue)"
                                ((error_count++))
                            fi
                        done
                        log_message INFO "Successfully deleted $delete_count empty directories."
                        if [ "$error_count" -gt 0 ]; then
                             log_message WARNING "$error_count directories could not be deleted."
                        fi
                    else
                        log_message INFO "Operation to delete empty directories cancelled by user."
                    fi
                fi
                read -p "Weiter..."
                ;;
            4)
                # Find large files under $HOME (>50MB)
                log_message INFO "Option 4: Find large files under $HOME (>50MB)"
                local size_threshold="+50M" # Standard find size format
                log_message INFO "Searching for files larger than 50MB under $HOME..."

                # Use an array to store found files and their sizes
                declare -A large_files_map # Associative array: path -> size
                local large_files_list=() # Array to maintain order and for selection

                # Populate the array and map
                # Using -print0 and xargs -0 for safety with filenames. du -h for human-readable sizes.
                while IFS= read -r line; do
                    # du -h output is like: 51M /path/to/file
                    # We need to extract size and path separately
                    local size=$(echo "$line" | awk '{print $1}')
                    local file_path=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[ \t]*//') # Remove first field (size) and leading spaces

                    if [ -n "$file_path" ]; then # Ensure file_path is not empty
                        large_files_map["$file_path"]="$size"
                        large_files_list+=("$file_path")
                    fi
                done < <(find "$HOME" -mindepth 1 -type f -size "$size_threshold" -print0 | xargs -0 du -h) # -mindepth 1 to exclude files directly in $HOME if $HOME itself matches size (unlikely)

                if [ ${#large_files_list[@]} -eq 0 ]; then
                    log_message INFO "No files larger than 50MB found under $HOME."
                else
                    log_message INFO "Found the following large files:"
                    for i in "${!large_files_list[@]}"; do
                        local file_path="${large_files_list[$i]}"
                        local file_size="${large_files_map[$file_path]}"
                        printf "  %2d. %s (%s)\n" "$((i+1))" "$file_path" "$file_size"
                    done
                    echo # Newline for readability

                    read -p "$(echo -e "${BOLD}${MAGENTA}Do you want to delete any of these files? (y/N):${NC} ")" confirm_delete_large
                    if [[ "$confirm_delete_large" =~ ^[Yy]$ ]]; then
                        read -p "$(echo -e "${BOLD}${MAGENTA}Enter numbers of files to delete (e.g., 1 3 4), or 'all':${NC} ")" files_to_delete_input

                        if [[ "$files_to_delete_input" == "all" ]]; then
                            log_message INFO "Attempting to delete all listed large files..."
                            for file_path in "${large_files_list[@]}"; do
                                echo -e "${YELLOW}Deleting '$file_path' (${large_files_map[$file_path]})...${NC}"
                                if rm -f "$file_path"; then # Use -f to avoid prompts from rm itself
                                    log_message INFO "Deleted: $file_path"
                                else
                                    log_message ERROR "Failed to delete: $file_path"
                                fi
                            done
                        elif [ -n "$files_to_delete_input" ]; then
                            local delete_indices=($files_to_delete_input) # Convert space-separated string to array
                            for index_str in "${delete_indices[@]}"; do
                                if [[ "$index_str" =~ ^[0-9]+$ ]]; then
                                    local index=$((index_str - 1)) # Adjust to 0-based index
                                    if [ "$index" -ge 0 ] && [ "$index" -lt "${#large_files_list[@]}" ]; then
                                        local file_path_to_delete="${large_files_list[$index]}"
                                        echo -e "${YELLOW}Deleting '$file_path_to_delete' (${large_files_map[$file_path_to_delete]})...${NC}"
                                        if rm -f "$file_path_to_delete"; then
                                            log_message INFO "Deleted: $file_path_to_delete"
                                        else
                                            log_message ERROR "Failed to delete: $file_path_to_delete"
                                        fi
                                    else
                                        log_message WARNING "Invalid selection: $index_str. Out of range."
                                    fi
                                else
                                     log_message WARNING "Invalid input: '$index_str'. Not a number."
                                fi
                            done
                        else
                            log_message INFO "No files selected for deletion."
                        fi
                    else
                        log_message INFO "No files will be deleted."
                    fi
                fi
                read -p "Weiter..."
                ;;
            q|Q)
                log_message INFO "Exiting System Maintenance Cleaner."
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
