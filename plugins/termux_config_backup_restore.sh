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
PLUGIN_CONFIG_DIR="$HOME/.termux_is_black_plugins_config"
PLUGIN_CONFIG_FILE="$PLUGIN_CONFIG_DIR/termux_config_backup.list"
BACKUP_DIR_BASE="$HOME/termux_config_backups"

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

    echo -e "${BOLD}${color}[TERMUX_CONFIG_BACKUP] ${type}:${NC} $message"
}

# Default configuration paths
DEFAULT_CONFIG_PATHS=(
    "$HOME/.termux/termux.properties"
    "$HOME/.bashrc"
    "$HOME/.profile"
    "$HOME/.gitconfig"
    "$HOME/.nanorc"
    "$HOME/.config/mc"
    "$HOME/.config/htop/htoprc"
    "$HOME/.ssh"
    "$HOME/.selected_editor" # Termux Startup specific
    "$HOME/.termux_startup.conf" # Termux Startup specific
)

# Ensure plugin config directory and file exist
ensure_plugin_config_exists() {
    if [ ! -d "$PLUGIN_CONFIG_DIR" ]; then
        log_message INFO "Creating plugin config directory: $PLUGIN_CONFIG_DIR"
        mkdir -p "$PLUGIN_CONFIG_DIR"
        if [ $? -ne 0 ]; then
            log_message ERROR "Failed to create plugin config directory. Exiting."
            read -p "Weiter..."
            exit 1 # Critical error
        fi
    fi

    if [ ! -f "$PLUGIN_CONFIG_FILE" ]; then
        log_message INFO "Plugin config file not found. Creating with default paths: $PLUGIN_CONFIG_FILE"
        # Create the file by printing each default path on a new line
        printf "%s\n" "${DEFAULT_CONFIG_PATHS[@]}" > "$PLUGIN_CONFIG_FILE"
        if [ $? -ne 0 ]; then
            log_message ERROR "Failed to create plugin config file. Exiting."
            read -p "Weiter..."
            exit 1 # Critical error
        fi
    else
        log_message INFO "Plugin config file found: $PLUGIN_CONFIG_FILE"
    fi
}

# Main function for the Termux Config Backup/Restore plugin
run_termux_config_backup_restore() {
    echo -e "${BOLD}${CYAN}==================================================${NC}"
    echo -e "${BOLD}${CYAN}=== Termux Configuration Backup & Restore v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}==================================================${NC}"
    echo # Newline for better readability

    # Ensure tar is installed
    if ! command -v tar &> /dev/null; then
        log_message ERROR "tar is not installed. Please install it to use this plugin."
        echo -e "${YELLOW}Installation instructions (example for Termux/Debian-based):${NC} apt update && apt install tar"
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "tar is installed."

    ensure_plugin_config_exists

    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. View/Edit backup paths"
        echo "  2. Create backup"
        echo "  3. Restore from backup"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1, 2, 3, q]:${NC} ")" choice

# Function to read paths from config file into an array
read_paths_from_config() {
    local paths_array=()
    if [ -f "$PLUGIN_CONFIG_FILE" ]; then
        mapfile -t paths_array < "$PLUGIN_CONFIG_FILE"
        # Remove empty lines that might have been read
        paths_array=("${paths_array[@]/#''/}") # This might not work as expected for empty lines
        # A more robust way to filter empty lines
        local temp_array=()
        for path in "${paths_array[@]}"; do
            if [ -n "$path" ]; then # Only add non-empty paths
                temp_array+=("$path")
            fi
        done
        paths_array=("${temp_array[@]}")
    fi
    # Return by echoing and letting caller capture
    # This is tricky with arrays. Instead, we'll pass array name as ref in bash 4.3+
    # For simplicity here, we'll make paths_array global-like within the plugin context or reload it.
    # For this iteration, will reload it where needed or manage it more directly.
}

# Function to save paths array to config file
save_paths_to_config() {
    local -n arr_ref=$1 # Pass array by reference (nameref)
    printf "%s\n" "${arr_ref[@]}" > "$PLUGIN_CONFIG_FILE"
    if [ $? -eq 0 ]; then
        log_message INFO "Backup paths saved to $PLUGIN_CONFIG_FILE"
    else
        log_message ERROR "Failed to save backup paths to $PLUGIN_CONFIG_FILE"
    fi
}


# Main function for the Termux Config Backup/Restore plugin
run_termux_config_backup_restore() {
    echo -e "${BOLD}${CYAN}==================================================${NC}"
    echo -e "${BOLD}${CYAN}=== Termux Configuration Backup & Restore v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}==================================================${NC}"
    echo # Newline for better readability

    # Ensure tar is installed
    if ! command -v tar &> /dev/null; then
        log_message ERROR "tar is not installed. Please install it to use this plugin."
        echo -e "${YELLOW}Installation instructions (example for Termux/Debian-based):${NC} apt update && apt install tar"
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "tar is installed."

    ensure_plugin_config_exists

    local current_backup_paths=() # To be managed by View/Edit

    local choice
    while true; do
        echo -e "\n${BOLD}${MAGENTA}Choose an action:${NC}"
        echo "  1. View/Edit backup paths"
        echo "  2. Create backup"
        echo "  3. Restore from backup"
        echo "  q. Quit"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1, 2, 3, q]:${NC} ")" choice

        case "$choice" in
            1) # View/Edit backup paths
                log_message INFO "View/Edit backup paths selected."
                mapfile -t current_backup_paths < "$PLUGIN_CONFIG_FILE" # Load current paths
                # Filter out empty lines
                local temp_paths=()
                for path in "${current_backup_paths[@]}"; do
                    if [ -n "$path" ]; then temp_paths+=("$path"); fi
                done
                current_backup_paths=("${temp_paths[@]}")


                while true; do
                    echo -e "\n  ${BOLD}${CYAN}Current backup paths:${NC}"
                    if [ ${#current_backup_paths[@]} -eq 0 ]; then
                        echo "    (No paths configured)"
                    else
                        for i in "${!current_backup_paths[@]}"; do
                            printf "    %2d. %s\n" "$((i+1))" "${current_backup_paths[$i]}"
                        done
                    fi

                    echo -e "\n  ${BOLD}${BLUE}Options:${NC}"
                    echo "    a. Add new path"
                    echo "    r. Remove a path (by number)"
                    echo "    s. Save changes and return to main menu"
                    echo "    d. Discard changes and return to main menu"
                    read -p "$(echo -e "  ${BOLD}${BLUE}Enter your choice [a, r, s, d]:${NC} ")" edit_choice

                    case "$edit_choice" in
                        a|A)
                            read -p "$(echo -e "    ${BOLD}${MAGENTA}Enter new path to add (e.g., $HOME/.config/another-app):${NC} ")" new_path
                            if [ -z "$new_path" ]; then
                                log_message WARNING "Path cannot be empty."
                            elif [[ " ${current_backup_paths[@]} " =~ " $new_path " ]]; then # Check if path already exists
                                log_message WARNING "Path '$new_path' already in the list."
                            else
                                # Validate if path exists for backup - good practice
                                # Using eval to expand tilde, then checking
                                local expanded_new_path
                                eval "expanded_new_path=\"$new_path\"" # Expand tilde, $HOME etc.

                                if [ -e "$expanded_new_path" ]; then
                                    current_backup_paths+=("$new_path") # Add the original path string, not the expanded one
                                    log_message INFO "Added path: $new_path"
                                else
                                    read -p "$(echo -e "    ${YELLOW}Path '$expanded_new_path' does not exist. Add anyway? (y/N):${NC} ")" confirm_add_nonexistent
                                    if [[ "$confirm_add_nonexistent" =~ ^[Yy]$ ]]; then
                                        current_backup_paths+=("$new_path")
                                        log_message INFO "Added non-existent path: $new_path (will be skipped if not found during backup)"
                                    else
                                        log_message INFO "Path '$new_path' not added."
                                    fi
                                fi
                            fi
                            ;;
                        r|R)
                            if [ ${#current_backup_paths[@]} -eq 0 ]; then
                                log_message WARNING "No paths to remove."
                                continue
                            fi
                            read -p "$(echo -e "    ${BOLD}${MAGENTA}Enter number of path to remove:${NC} ")" remove_num
                            if [[ "$remove_num" =~ ^[0-9]+$ ]] && [ "$remove_num" -ge 1 ] && [ "$remove_num" -le "${#current_backup_paths[@]}" ]; then
                                local index_to_remove=$((remove_num - 1))
                                local removed_path="${current_backup_paths[$index_to_remove]}"
                                current_backup_paths=("${current_backup_paths[@]:0:$index_to_remove}" "${current_backup_paths[@]:$((index_to_remove + 1))}")
                                log_message INFO "Removed path: $removed_path"
                            else
                                log_message ERROR "Invalid number: '$remove_num'."
                            fi
                            ;;
                        s|S)
                            save_paths_to_config current_backup_paths # Pass array name
                            break # Back to main menu
                            ;;
                        d|D)
                            log_message INFO "Changes discarded."
                            break # Back to main menu
                            ;;
                        *)
                            log_message ERROR "Invalid choice."
                            ;;
                    esac
                done
                read -p "Weiter..."
                ;;
            2) # Create backup
                log_message INFO "Create backup selected."
                if [ ! -d "$BACKUP_DIR_BASE" ]; then
                    log_message INFO "Backup directory '$BACKUP_DIR_BASE' not found. Creating..."
                    mkdir -p "$BACKUP_DIR_BASE"
                    if [ $? -ne 0 ]; then
                        log_message ERROR "Failed to create backup directory '$BACKUP_DIR_BASE'. Cannot proceed."
                        read -p "Weiter..."
                        continue
                    fi
                fi

                mapfile -t current_backup_paths < "$PLUGIN_CONFIG_FILE"
                local valid_paths_to_backup=()
                log_message INFO "Validating paths from $PLUGIN_CONFIG_FILE..."
                for path_pattern in "${current_backup_paths[@]}"; do
                    if [ -z "$path_pattern" ]; then continue; fi # Skip empty lines

                    local expanded_path
                    eval "expanded_path=\"$path_pattern\"" # Expand tilde, $HOME etc.

                    if [ -e "$expanded_path" ]; then
                        # Check if path is within $HOME for safety, or adjust tar options
                        # For now, we assume paths are mostly under $HOME or user knows what they are doing.
                        # Tar needs paths relative to current dir, or absolute.
                        # If we cd to $HOME, paths should be relative to $HOME.
                        # If we use absolute paths, tar stores them as absolute.
                        # Using --transform to make paths relative in archive is an option.
                        # For simplicity, we'll use absolute paths for now, and -P for tar to handle them.
                        valid_paths_to_backup+=("$expanded_path")
                        log_message DEBUG "Path valid and exists: $expanded_path"
                    else
                        log_message WARNING "Path '$path_pattern' (expanded: '$expanded_path') does not exist. Skipping."
                    fi
                done

                if [ ${#valid_paths_to_backup[@]} -eq 0 ]; then
                    log_message ERROR "No valid paths found to back up. Check $PLUGIN_CONFIG_FILE."
                    read -p "Weiter..."
                    continue
                fi

                local timestamp=$(date +%Y%m%d_%H%M%S)
                local backup_file_name="termux_config_${timestamp}.tar.gz"
                local backup_file_path="$BACKUP_DIR_BASE/$backup_file_name"

                log_message INFO "The following paths will be included in the backup:"
                for p in "${valid_paths_to_backup[@]}"; do echo "  - $p"; done

                log_message INFO "Creating backup archive: $backup_file_path"

                # Using -P option to store absolute paths.
                # For restore, we'll extract to $HOME and hope paths are structured to match.
                # A better way for restore would be to strip leading components or use --strip-components
                # if paths in tar are like /data/data/com.termux/files/home/...
                # Or ensure paths stored are relative to $HOME and cd to $HOME before tarring.
                # Let's try to make paths relative to $HOME for tarring.
                local paths_for_tar=()
                for p_abs in "${valid_paths_to_backup[@]}"; do
                    # Attempt to make path relative to $HOME if it's inside $HOME
                    if [[ "$p_abs" == "$HOME/"* ]]; then
                        paths_for_tar+=("${p_abs#$HOME/}")
                    else
                        # If path is outside $HOME, it's more complex.
                        # For now, we'll add it as is, but this might be problematic for restore.
                        # tar will store it as an absolute path if -P is used, or relative to CWD.
                        # Let's stick to paths relative to $HOME for items within $HOME.
                        # And absolute for those outside if user insists (though not recommended here)
                        # For this version, let's focus on $HOME contents.
                        # If we 'cd $HOME', then all paths starting with $HOME/ can be relative.
                        log_message WARNING "Path $p_abs is outside $HOME. Backup of such paths can be complex to restore correctly. Storing as is."
                        paths_for_tar+=("$p_abs") # This will be problematic if not using -P and not in CWD
                    fi
                done


                # Create a temporary list file for paths to avoid issues with too many arguments
                local temp_path_list_file=$(mktemp)
                printf "%s\n" "${paths_for_tar[@]}" > "$temp_path_list_file"

                # We will cd to $HOME to make paths relative for items within $HOME.
                # For items outside $HOME (if any allowed by future logic), they would need absolute paths and -P.
                # Current logic with paths_for_tar makes them relative to $HOME if they were in $HOME.
                if (cd "$HOME" && tar -czf "$backup_file_path" --files-from="$temp_path_list_file" --ignore-failed-read); then
                    log_message INFO "Backup created successfully: $backup_file_path"
                else
                    log_message ERROR "Failed to create backup archive. Tar exit code: $?"
                fi
                rm -f "$temp_path_list_file"

                read -p "Weiter..."
                ;;
            3) # Restore from backup
                log_message INFO "Restore from backup selected."
                if [ ! -d "$BACKUP_DIR_BASE" ] || [ -z "$(ls -A "$BACKUP_DIR_BASE"/*.tar.gz 2>/dev/null)" ]; then
                    log_message WARNING "No backup directory found or no backup files (.tar.gz) in '$BACKUP_DIR_BASE'."
                    read -p "Weiter..."
                    continue
                fi

                log_message INFO "Available backups in '$BACKUP_DIR_BASE':"
                local backup_files=()
                # Use find to get .tar.gz files and store them in an array
                while IFS= read -r file; do
                    backup_files+=("$file")
                done < <(find "$BACKUP_DIR_BASE" -maxdepth 1 -name "*.tar.gz" -type f -printf "%f\n" | sort -r) # Sort reverse to get newest first

                if [ ${#backup_files[@]} -eq 0 ]; then
                    log_message WARNING "No .tar.gz backup files found in '$BACKUP_DIR_BASE'."
                    read -p "Weiter..."
                    continue
                fi

                for i in "${!backup_files[@]}"; do
                    printf "  %2d. %s\n" "$((i+1))" "${backup_files[$i]}"
                done

                local selected_backup_num
                read -p "$(echo -e "${BOLD}${MAGENTA}Enter number of backup to restore:${NC} ")" selected_backup_num

                if [[ "$selected_backup_num" =~ ^[0-9]+$ ]] && \
                   [ "$selected_backup_num" -ge 1 ] && \
                   [ "$selected_backup_num" -le "${#backup_files[@]}" ]; then

                    local selected_backup_name="${backup_files[$((selected_backup_num - 1))]}"
                    local selected_backup_path="$BACKUP_DIR_BASE/$selected_backup_name"
                    log_message INFO "Selected backup for restore: $selected_backup_path"

                    echo -e "${BOLD}${RED}WARNING: Restoring will overwrite current configuration files!${NC}"
                    read -p "$(echo -e "${BOLD}${MAGENTA}Are you sure you want to continue? (y/N):${NC} ")" confirm_restore
                    if [[ ! "$confirm_restore" =~ ^[Yy]$ ]]; then
                        log_message INFO "Restore operation cancelled by user."
                        read -p "Weiter..."
                        continue
                    fi

                    # Pre-restore backup logic
                    local pre_restore_backup_name="pre_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
                    local pre_restore_backup_path="$BACKUP_DIR_BASE/$pre_restore_backup_name"
                    local files_to_prerestore_backup=()

                    log_message INFO "Checking for files that would be overwritten by restore..."
                    # Get list of files from the selected backup archive
                    # Ensure paths are relative to $HOME if they were stored that way.
                    # The create backup logic stores paths relative to $HOME in the tarball.
                    # So, tar -tf will list them relative to the archive root.
                    # These need to be prefixed with $HOME to check existence.
                    while IFS= read -r archived_file_rel_path; do
                        local full_path_to_check="$HOME/$archived_file_rel_path"
                        if [ -e "$full_path_to_check" ]; then # Check if file/dir exists at target location
                            files_to_prerestore_backup+=("$archived_file_rel_path") # Add relative path for tar
                        fi
                    done < <(tar -tf "$selected_backup_path")

                    if [ ${#files_to_prerestore_backup[@]} -gt 0 ]; then
                        log_message INFO "The following existing files/directories will be part of a pre-restore backup:"
                        for f in "${files_to_prerestore_backup[@]}"; do echo "  - $HOME/$f"; done

                        read -p "$(echo -e "${BOLD}${MAGENTA}Create a pre-restore backup of these conflicting files/dirs? (Y/n):${NC} ")" confirm_pre_restore_backup
                        confirm_pre_restore_backup=${confirm_pre_restore_backup:-Y} # Default to Yes

                        if [[ "$confirm_pre_restore_backup" =~ ^[Yy]$ ]]; then
                            log_message INFO "Creating pre-restore backup: $pre_restore_backup_path"
                            local temp_prerestore_list=$(mktemp)
                            printf "%s\n" "${files_to_prerestore_backup[@]}" > "$temp_prerestore_list"

                            if (cd "$HOME" && tar -czf "$pre_restore_backup_path" --files-from="$temp_prerestore_list" --ignore-failed-read); then
                                log_message INFO "Pre-restore backup created successfully: $pre_restore_backup_path"
                            else
                                log_message ERROR "Failed to create pre-restore backup. Restore aborted."
                                rm -f "$temp_prerestore_list"
                                read -p "Weiter..."
                                continue # Abort restore
                            fi
                            rm -f "$temp_prerestore_list"
                        else
                            log_message INFO "Skipping pre-restore backup."
                        fi
                    else
                        log_message INFO "No existing files found that would be overwritten. No pre-restore backup needed."
                    fi

                    # Proceed with actual restore
                    log_message INFO "Restoring from '$selected_backup_path' to '$HOME'..."
                    # Extracting to $HOME. Paths in tarball are relative to $HOME.
                    if tar -xzf "$selected_backup_path" -C "$HOME"; then
                        log_message INFO "Restore completed successfully."
                    else
                        log_message ERROR "Failed to restore from backup. Tar exit code: $?"
                        log_message ERROR "Your system might be in an inconsistent state. Review any error messages."
                    fi
                else
                    log_message ERROR "Invalid backup number selected."
                fi
                read -p "Weiter..."
                ;;
            q|Q)
                log_message INFO "Exiting Termux Config Backup & Restore."
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
