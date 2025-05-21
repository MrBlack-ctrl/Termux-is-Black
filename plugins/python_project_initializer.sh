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

    echo -e "${BOLD}${color}[PYTHON_PROJECT_INITIALIZER] ${type}:${NC} $message"
}

# Main function for the Python Project Initializer plugin
run_python_project_initializer() {
    echo -e "${BOLD}${CYAN}=========================================${NC}"
    echo -e "${BOLD}${CYAN}=== Python Project Initializer v${PLUGIN_VERSION} ===${NC}"
    echo -e "${BOLD}${CYAN}=========================================${NC}"
    echo # Newline for better readability

    # Load PYTHON_CMD from config or default to python3
    PYTHON_CMD="python3"
    if [ -f "$HOME/.termux_startup.conf" ]; then
        # Source the config file in a subshell to avoid polluting the current environment
        # and grep for PYTHON_CMD specifically.
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

    # Prompt for project name
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter project name:${NC} ")" PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        log_message ERROR "Project name cannot be empty."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Project name: '$PROJECT_NAME'"

    # Prompt for base path
    read -p "$(echo -e "${BOLD}${MAGENTA}Enter base path for the new project (default: $PWD):${NC} ")" BASE_PATH
    BASE_PATH="${BASE_PATH:-$PWD}" # Default to current directory if empty

    # Validate base path
    if [ ! -d "$BASE_PATH" ]; then
        log_message ERROR "Base path '$BASE_PATH' is not a valid directory."
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Base path: '$BASE_PATH'"

    FULL_PROJECT_PATH="$BASE_PATH/$PROJECT_NAME"
    log_message INFO "Full project path will be: '$FULL_PROJECT_PATH'"

    # Check if project directory already exists
    if [ -d "$FULL_PROJECT_PATH" ]; then
        log_message ERROR "Project directory '$FULL_PROJECT_PATH' already exists."
        read -p "Weiter..."
        return 1
    fi

    # Create project directories
    log_message INFO "Creating project directory structure at '$FULL_PROJECT_PATH'..."
    mkdir -p "$FULL_PROJECT_PATH/src"
    if [ $? -ne 0 ]; then
        log_message ERROR "Failed to create project directory '$FULL_PROJECT_PATH/src'."
        read -p "Weiter..."
        return 1
    fi
    mkdir -p "$FULL_PROJECT_PATH/tests"
     if [ $? -ne 0 ]; then
        log_message ERROR "Failed to create project directory '$FULL_PROJECT_PATH/tests'."
        # Attempt to clean up already created directory
        rm -rf "$FULL_PROJECT_PATH"
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Directories 'src' and 'tests' created successfully."

    # Create README.md
    touch "$FULL_PROJECT_PATH/README.md"
    if [ $? -ne 0 ]; then
        log_message ERROR "Failed to create README.md."
        rm -rf "$FULL_PROJECT_PATH"
        read -p "Weiter..."
        return 1
    fi
    echo "# $PROJECT_NAME" > "$FULL_PROJECT_PATH/README.md"
    echo "" >> "$FULL_PROJECT_PATH/README.md"
    echo "This project was initialized by the Termux Startup Script Python Initializer." >> "$FULL_PROJECT_PATH/README.md"
    log_message INFO "Created README.md"

    # Create .gitignore
    touch "$FULL_PROJECT_PATH/.gitignore"
    if [ $? -ne 0 ]; then
        log_message ERROR "Failed to create .gitignore."
        rm -rf "$FULL_PROJECT_PATH"
        read -p "Weiter..."
        return 1
    fi
    cat << EOF > "$FULL_PROJECT_PATH/.gitignore"
# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtualenv
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDEs and editors
.idea/
.vscode/
*.swp
*.swo
*.DS_Store

# OS generated files
Thumbs.db
ehthumbs.db
Desktop.ini
.AppleDouble
.LSOverride

# Other
*.log
*.pot
*.py[cod]
*.sqlite3
*.coverage
*.local
EOF
    log_message INFO "Created .gitignore"

    # Create requirements.txt
    touch "$FULL_PROJECT_PATH/requirements.txt"
    if [ $? -ne 0 ]; then
        log_message ERROR "Failed to create requirements.txt."
        rm -rf "$FULL_PROJECT_PATH"
        read -p "Weiter..."
        return 1
    fi
    log_message INFO "Created empty requirements.txt"

    # Ask to initialize Git repository
    read -p "$(echo -e "${BOLD}${MAGENTA}Initialize Git repository? (y/N):${NC} ")" INIT_GIT
    if [[ "$INIT_GIT" =~ ^[Yy]$ ]]; then
        if ! command -v git &> /dev/null; then
            log_message WARNING "git command not found. Skipping Git initialization."
        else
            log_message INFO "Initializing Git repository..."
            if (cd "$FULL_PROJECT_PATH" && git init && git add . && git commit -m "Initial project structure by TermuxStartup"); then
                log_message INFO "Git repository initialized and initial commit made."
            else
                log_message ERROR "Failed to initialize Git repository."
            fi
        fi
    else
        log_message INFO "Skipping Git initialization."
    fi

    # Ask to create Python virtual environment
    read -p "$(echo -e "${BOLD}${MAGENTA}Create Python virtual environment (.venv)? (y/N):${NC} ")" CREATE_VENV
    if [[ "$CREATE_VENV" =~ ^[Yy]$ ]]; then
        log_message INFO "Checking for venv module with $PYTHON_CMD..."
        if ! $PYTHON_CMD -m venv -h &> /dev/null; then # Simple check if venv module is accessible
            log_message WARNING "$PYTHON_CMD -m venv not available. Skipping virtual environment creation."
            log_message WARNING "You might need to install it (e.g., apt install python3-venv or similar for your Python version)."
        else
            log_message INFO "Creating Python virtual environment in '$FULL_PROJECT_PATH/.venv' using '$PYTHON_CMD'..."
            if $PYTHON_CMD -m venv "$FULL_PROJECT_PATH/.venv"; then
                log_message INFO "Python virtual environment created successfully."
                echo "" >> "$FULL_PROJECT_PATH/.gitignore" # Add a newline
                echo "# Virtual Environment" >> "$FULL_PROJECT_PATH/.gitignore"
                echo ".venv/" >> "$FULL_PROJECT_PATH/.gitignore"
                log_message INFO "Added '.venv/' to .gitignore"
                log_message INFO "To activate it, run: source $FULL_PROJECT_PATH/.venv/bin/activate"
            else
                log_message ERROR "Failed to create Python virtual environment."
            fi
        fi
    else
        log_message INFO "Skipping Python virtual environment creation."
    fi

    log_message INFO "Project '$PROJECT_NAME' created successfully at '$FULL_PROJECT_PATH'."
    read -p "Weiter..."
}

log_message INFO "Plugin loaded (Version: ${PLUGIN_VERSION})"
