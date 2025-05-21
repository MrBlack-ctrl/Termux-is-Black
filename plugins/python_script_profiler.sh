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

    echo -e "${BOLD}${color}[PY_PROFILER] ${type}:${NC} $message"
}

# Main function for the Python Script Profiler plugin
run_python_script_profiler() {
    echo -e "${BOLD}${CYAN}=======================================${NC}"
    echo -e "${BOLD}${CYAN}=== Python Script Profiler v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}=======================================${NC}"
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

    # Check if cProfile module is available
    if ! $PYTHON_CMD -m cProfile -h &> /dev/null; then
        log_message ERROR "The 'cProfile' module is not available for '$PYTHON_CMD'."
        log_message ERROR "Please ensure your Python installation is correct and includes the cProfile module."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "'cProfile' module found for '$PYTHON_CMD'."

    local script_path
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter the path to the Python script to profile:${NC} ")" script_path

    if [ -z "$script_path" ]; then
        log_message ERROR "Script path cannot be empty."
        read -p "Weiter..."
        return 1
    fi
    if [ ! -f "$script_path" ] || [ ! -r "$script_path" ]; then
        log_message ERROR "Script '$script_path' not found or is not readable."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Script to profile: '$script_path'"

    local script_args
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter command-line arguments for the script (if any):${NC} ")" script_args
    log_message INFO "Script arguments: '$script_args'"

    local save_to_file_choice
    read -p "$(echo -e "${BOLD}${MAGENTA}Save profiling output to a file? (y/N):${NC} ")" save_to_file_choice

    local output_file_path=""
    if [[ "$save_to_file_choice" =~ ^[Yy]$ ]]; then
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter output file name (e.g., profile_output.stats):${NC} ")" output_file_name
        if [ -z "$output_file_name" ]; then
            log_message WARNING "Output file name is empty. Defaulting to 'profile_output.stats'."
            output_file_name="profile_output.stats"
        fi
        # Use current directory for the output file, or allow absolute path?
        # For simplicity, let's assume current directory or user provides full path.
        # If it's just a name, it will be in PWD.
        if [[ "$output_file_name" == */* ]]; then
            output_file_path="$output_file_name"
        else
            output_file_path="$PWD/$output_file_name"
        fi
        
        local output_dir=$(dirname "$output_file_path")
        if [ ! -d "$output_dir" ]; then
            log_message WARNING "Directory '$output_dir' for output file does not exist. Attempting to create it."
            if mkdir -p "$output_dir"; then
                log_message INFO "Created directory '$output_dir'."
            else
                log_message ERROR "Failed to create directory '$output_dir'. Cannot save profiling output."
                read -p "Weiter..."
                return 1
            fi
        fi
        log_message INFO "Profiling output will be saved to: '$output_file_path'"
    else
        log_message INFO "Profiling output will be displayed on the console."
    fi

    # Construct the command
    # Using an array for the command and arguments is safer, especially if script_path or script_args contain spaces.
    local cmd_array=()
    cmd_array+=("$PYTHON_CMD")
    cmd_array+=("-m")
    cmd_array+=("cProfile")
    cmd_array+=("-s")
    cmd_array+=("tottime") # Sort by total time spent in function
    cmd_array+=("$script_path")

    # Add script arguments only if they are provided
    # Note: This simple word splitting might not handle complex arguments with spaces perfectly.
    # For robust argument parsing, one might need a more complex approach or tell users to quote args.
    if [ -n "$script_args" ]; then
        # Convert string of arguments to an array
        read -r -a parsed_args <<< "$script_args"
        cmd_array+=("${parsed_args[@]}")
    fi

    log_message INFO "Executing profiling command: ${cmd_array[*]}"

    if [ -n "$output_file_path" ]; then
        # Execute and redirect to file
        # Using eval here to correctly handle argument parsing for script_args.
        # A bit risky if script_args is malicious, but common for such tools.
        # Safer: "${cmd_array[@]}" > "$output_file_path"
        if eval "${cmd_array[@]}" > "$output_file_path" 2>&1; then
            log_message INFO "Profiling finished. Output saved to '$output_file_path'."
            echo -e "${GREEN}You can view the stats using a stats viewer or by printing the file.${NC}"
            echo -e "${GREEN}Example: $PYTHON_CMD -m pstats '$output_file_path'${NC}"
        else
            log_message ERROR "Profiling failed or script error. Check '$output_file_path' if it was created, or console for errors."
        fi
    else
        # Execute and display on console
        echo -e "${CYAN}--- Profiling Output Start ---${NC}"
        # Using eval for same reasons as above.
        if eval "${cmd_array[@]}"; then
            log_message INFO "Profiling finished."
        else
            log_message ERROR "Profiling failed or script error."
        fi
        echo -e "${CYAN}--- Profiling Output End ---${NC}"
    fi

    read -p "Weiter..."
}

log_message INFO "Plugin loaded (Version: ${PLUGIN_VERSION})"
