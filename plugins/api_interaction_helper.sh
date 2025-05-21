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

    echo -e "${BOLD}${color}[API_HELPER] ${type}:${NC} $message"
}

# Main function for the API Interaction Helper plugin
run_api_interaction_helper() {
    echo -e "${BOLD}${CYAN}=======================================${NC}"
    echo -e "${BOLD}${CYAN}=== API Interaction Helper v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}=======================================${NC}"
    echo # Newline for better readability

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        log_message ERROR "curl is not installed. Please install it to use this plugin."
        echo -e "${YELLOW}Installation instructions (example for Termux/Debian-based):${NC} apt update && apt install curl"
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "curl is installed."

    local request_url
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter Request URL:${NC} ")" request_url
    if [ -z "$request_url" ]; then
        log_message ERROR "Request URL cannot be empty."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Request URL: $request_url"

    local http_method
    echo -e "${BOLD}${MAGENTA}Select HTTP Method:${NC}"
    echo "  1. GET (default)"
    echo "  2. POST"
    echo "  3. PUT"
    echo "  4. DELETE"
    echo "  5. PATCH"
    echo "  6. HEAD"
    echo "  7. OPTIONS"
    echo "  Or enter custom method (e.g., TRACE)"
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice or custom method [GET]:${NC} ")" method_choice
    method_choice="${method_choice:-GET}" # Default to GET

    case "$method_choice" in
        1|GET|get) http_method="GET" ;;
        2|POST|post) http_method="POST" ;;
        3|PUT|put) http_method="PUT" ;;
        4|DELETE|delete) http_method="DELETE" ;;
        5|PATCH|patch) http_method="PATCH" ;;
        6|HEAD|head) http_method="HEAD" ;;
        7|OPTIONS|options) http_method="OPTIONS" ;;
        *)
            # Validate custom method (basic: uppercase, no spaces)
            if [[ "$method_choice" =~ ^[A-Z]+$ ]]; then
                http_method="$method_choice"
                log_message INFO "Using custom HTTP method: $http_method"
            else
                log_message WARNING "Invalid custom method '$method_choice'. Defaulting to GET."
                http_method="GET"
            fi
            ;;
    esac
    log_message INFO "HTTP Method: $http_method"

    # Add custom headers
    local headers_array=()
    while true; do
        read -p "$(echo -e "${BOLD}${MAGENTA}Add custom header? (y/N):${NC} ")" add_header_choice
        if [[ "$add_header_choice" =~ ^[Yy]$ ]]; then
            read -p "$(echo -e "  ${BOLD}${CYAN}Enter header (e.g., Content-Type: application/json):${NC} ")" header_input
            if [ -n "$header_input" ]; then
                # Basic validation: check for colon
                if [[ "$header_input" == *":"* ]]; then
                    headers_array+=("$header_input")
                    log_message INFO "Added header: $header_input"
                else
                    log_message WARNING "Invalid header format. Missing colon ':'. Header not added."
                fi
            else
                log_message WARNING "Header input is empty. Not added."
            fi
        else
            break
        fi
    done

    local data_string=""
    local data_type="" # "raw" or "form"
    local form_data_array=() # For key=value pairs

    if [[ "$http_method" == "POST" || "$http_method" == "PUT" || "$http_method" == "PATCH" ]]; then
        echo -e "${BOLD}${MAGENTA}Select data type for $http_method request:${NC}"
        echo "  1. Raw (e.g., JSON, XML, plain text)"
        echo "  2. Form (application/x-www-form-urlencoded)"
        read -p "$(echo -e "${BOLD}${MAGENTA}Enter your choice [1]:${NC} ")" data_type_choice
        data_type_choice="${data_type_choice:-1}"

        if [[ "$data_type_choice" == "1" || "$data_type_choice" =~ ^[Rr]([Aa][Ww])?$ ]]; then
            data_type="raw"
            log_message INFO "Data type: Raw"
            read -p "$(echo -e "  ${BOLD}${CYAN}Enter raw data string (e.g., '{\"key\":\"value\"}'):${NC} ")" raw_data_input
            data_string="$raw_data_input"
        elif [[ "$data_type_choice" == "2" || "$data_type_choice" =~ ^[Ff]([Oo][Rr][Mm])?$ ]]; then
            data_type="form"
            log_message INFO "Data type: Form (application/x-www-form-urlencoded)"
            # Add a default Content-Type for form data if not already set by user
            local has_form_content_type=false
            for header in "${headers_array[@]}"; do
                if [[ "$header" == "Content-Type: application/x-www-form-urlencoded"* ]]; then
                    has_form_content_type=true
                    break
                fi
            done
            if ! $has_form_content_type; then
                 headers_array+=("Content-Type: application/x-www-form-urlencoded")
                 log_message INFO "Automatically added header: Content-Type: application/x-www-form-urlencoded"
            fi

            log_message INFO "Enter form data as key=value pairs. Press Enter on an empty line to finish."
            while true; do
                read -p "$(echo -e "    ${BOLD}${CYAN}key=value:${NC} ")" form_pair
                if [ -z "$form_pair" ]; then
                    break
                fi
                if [[ "$form_pair" == *"="* ]]; then
                    form_data_array+=("$form_pair")
                    log_message DEBUG "Added form data: $form_pair"
                else
                    log_message WARNING "Invalid form data format '$form_pair'. Should be key=value. Not added."
                fi
            done
            if [ ${#form_data_array[@]} -eq 0 ]; then
                log_message WARNING "No form data provided."
            fi
        else
            log_message WARNING "Invalid data type choice. No data will be sent."
        fi
    fi

    # Construct curl command
    local curl_cmd_array=()
    curl_cmd_array+=("curl")
    curl_cmd_array+=("-i") # Include response headers in output
    curl_cmd_array+=("-s") # Silent mode (don't show progress meter)
    curl_cmd_array+=("-S") # Show error even if -s is used
    curl_cmd_array+=("-X")
    curl_cmd_array+=("$http_method")

    for header in "${headers_array[@]}"; do
        curl_cmd_array+=("-H")
        curl_cmd_array+=("$header")
    done

    if [[ "$data_type" == "raw" ]] && [ -n "$data_string" ]; then
        curl_cmd_array+=("-d")
        curl_cmd_array+=("$data_string") # Quoting handled by curl array expansion
    elif [[ "$data_type" == "form" ]] && [ ${#form_data_array[@]} -gt 0 ]; then
        for pair in "${form_data_array[@]}"; do
            curl_cmd_array+=("--data-urlencode")
            curl_cmd_array+=("$pair")
        done
    fi

    curl_cmd_array+=("$request_url")

    log_message INFO "Executing command: ${curl_cmd_array[*]}"
    echo -e "${CYAN}--- Requesting... ---${NC}"

    # Execute curl and capture output
    # Using process substitution to avoid subshell issues with variables
    # Store entire output (headers + body)
    local full_response
    full_response=$(eval "${curl_cmd_array[*]}")
    local curl_exit_code=$?

    if [ $curl_exit_code -ne 0 ]; then
        log_message ERROR "curl command failed with exit code $curl_exit_code."
        echo -e "${RED}--- Curl Error Output ---${NC}"
        # The error might be in full_response if -S was effective, or just the exit code if not.
        # If full_response is empty and error code is non-zero, it means curl itself had a critical error.
        if [ -n "$full_response" ]; then
            echo "$full_response"
        else
            echo "Curl failed to execute or produce output. Check command syntax or network."
        fi
         echo -e "${RED}--- End Curl Error Output ---${NC}"
    else
        log_message INFO "curl command executed successfully."
        # Separate headers and body
        # Headers end with \r\n\r\n or \n\n
        # Read lines until an empty line is found
        local response_headers=""
        local response_body=""
        local in_headers=true

        # Handle potential carriage returns in headers (\r\n)
        # Convert \r\n to \n first for easier processing
        full_response_normalized=$(echo "$full_response" | tr -d '\r')

        while IFS= read -r line; do
            if $in_headers; then
                if [ -z "$line" ]; then # Empty line signifies end of headers
                    in_headers=false
                else
                    response_headers+="$line\n"
                fi
            else
                response_body+="$line\n" # Add back newline removed by read
            fi
        done <<< "$full_response_normalized"

        # Trim trailing newline from body if any
        response_body=${response_body%\\n}


        echo -e "\n${BOLD}${GREEN}--- Response Headers ---${NC}"
        echo -e "$response_headers"
        echo -e "${BOLD}${GREEN}--- Response Body ---${NC}"
        echo -e "$response_body"

        # Offer to save body to file
        read -p "$(echo -e "\n${BOLD}${MAGENTA}Save response body to a file? (y/N):${NC} ")" save_body_choice
        if [[ "$save_body_choice" =~ ^[Yy]$ ]]; then
            read -p "$(echo -e "  ${BOLD}${CYAN}Enter output file name (e.g., response.json):${NC} ")" body_output_file
            if [ -n "$body_output_file" ]; then
                local body_output_path
                if [[ "$body_output_file" == */* ]]; then # User provided path
                    body_output_path="$body_output_file"
                else # Just a filename, use current directory
                    body_output_path="$PWD/$body_output_file"
                fi
                
                local body_output_dir=$(dirname "$body_output_path")
                if [ ! -d "$body_output_dir" ]; then
                    mkdir -p "$body_output_dir" || log_message WARNING "Could not create directory '$body_output_dir' for saving file."
                fi

                if echo -n "$response_body" > "$body_output_path"; then # Use echo -n to avoid extra newline
                    log_message INFO "Response body saved to '$body_output_path'."
                else
                    log_message ERROR "Failed to save response body to '$body_output_path'."
                fi
            else
                log_message WARNING "Output file name is empty. Body not saved."
            fi
        fi

        # Check for jq and JSON content type
        local content_type_header=$(echo "$response_headers" | grep -i '^Content-Type:' | head -n 1)
        if command -v jq &> /dev/null && [[ "$content_type_header" == *"/json"* || "$content_type_header" == *"+json"* ]]; then
            log_message INFO "jq is installed and content type appears to be JSON."
            read -p "$(echo -e "${BOLD}${MAGENTA}Pipe response body through jq for pretty-printing? (y/N):${NC} ")" use_jq_choice
            if [[ "$use_jq_choice" =~ ^[Yy]$ ]]; then
                echo -e "\n${BOLD}${GREEN}--- JQ Formatted Response Body ---${NC}"
                echo "$response_body" | jq
                echo -e "${BOLD}${GREEN}--- End JQ Output ---${NC}"
            fi
        elif [[ "$content_type_header" == *"/json"* || "$content_type_header" == *"+json"* ]] && ! command -v jq &> /dev/null; then
            log_message WARNING "Content type is JSON, but jq is not installed. Skipping pretty-printing."
            echo -e "${YELLOW}Install jq for JSON pretty-printing: apt install jq${NC}"
        fi
    fi

    read -p "Weiter..."
}

log_message INFO "Plugin loaded (Version: ${PLUGIN_VERSION})"
