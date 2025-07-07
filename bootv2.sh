#!/bin/bash

# Set strict error handling
set -euo pipefail

# Function to display ASCII banner
show_banner() {
    echo "  _____            _        _                          _     "
    echo " |  __ \          | |      | |                        | |    "
    echo " | |  | | ___  ___| |_     | |__   ___  _   _ ___  ___| |__  "
    echo " | |  | |/ _ \/ __| __|    | '_ \ / _ \| | | / __|/ _ \ '_ \ "
    echo " | |__| |  __/\__ \ |_ _   | | | | (_) | |_| \__ \  __/ |_) |"
    echo " |_____/ \___||___/\__( )  |_| |_|\___/ \__,_|___/\___|_.__/ "
    echo "                      |/                                    "
    echo ""
    echo "Desktop Setup Bootstrap"
    echo "======================="
    echo ""
}

# Function to check for required commands
check_requirements() {
    echo "Checking requirements..."
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        if command -v gum >/dev/null 2>&1; then
            gum format --theme=warm "❌ Git is required but not installed. Aborting."
        else
            echo "❌ Git is required but not installed. Aborting."
        fi
        exit 1
    fi
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        if command -v gum >/dev/null 2>&1; then
            gum format --theme=warm "❌ Sudo privileges required. Please run with sudo access."
        else
            echo "❌ Sudo privileges required. Please run with sudo access."
        fi
        exit 1
    fi
    
    # Check for gum (install if not present)
    if ! command -v gum >/dev/null 2>&1; then
        echo "Installing gum for better user experience..."
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm gum
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y gum
        else
            echo "Warning: gum not available, using basic prompts"
        fi
    fi
    
    echo "✅ Requirements check passed"
}

# Function to clone or update repository
update_repository() {
    # Set default branch if not specified
    DESKTOP_REF=${DESKTOP_REF:-master}
    REPO_URL=${REPO_URL:-https://github.com/cypheroxide/desktop-setup.git}
    REPO_PATH="$HOME/.local/share/desktop-setup"
    
    echo "Setting up repository..."
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$REPO_PATH")"
    
    if [ -d "$REPO_PATH" ]; then
        echo "Repository exists, updating..."
        cd "$REPO_PATH"
        git fetch origin
        git checkout "$DESKTOP_REF"
        git pull origin "$DESKTOP_REF"
        echo "✅ Repository updated to branch: $DESKTOP_REF"
    else
        echo "Cloning repository..."
        git clone --branch "$DESKTOP_REF" "$REPO_URL" "$REPO_PATH"
        echo "✅ Repository cloned to: $REPO_PATH"
    fi
}

# Error trap function
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    if command -v gum >/dev/null 2>&1; then
        gum format --theme=warm "❌ Error occurred on line $line_number (exit code: $exit_code)"
    else
        echo "❌ Error occurred on line $line_number (exit code: $exit_code)"
    fi
    
    exit $exit_code
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Main function
main() {
    show_banner
    check_requirements

    # User confirmation
    if command -v gum >/dev/null 2>&1; then
        gum confirm "Do you want to proceed with the desktop setup?" || {
            gum format --theme=warm "Setup cancelled by user."
            exit 0
        }
    else
        echo -n "Do you want to proceed with the desktop setup? (y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                echo "Proceeding with setup..."
                ;;
            *)
                echo "Setup cancelled by user."
                exit 0
                ;;
        esac
    fi

    update_repository

    # Call install.sh
    echo "Calling install.sh..."
    if [ -f "$HOME/.local/share/desktop-setup/install.sh" ]; then
        chmod +x "$HOME/.local/share/desktop-setup/install.sh"
        "$HOME/.local/share/desktop-setup/install.sh"
    else
        if command -v gum >/dev/null 2>&1; then
            gum format --theme=warm "❌ install.sh not found in repository"
        else
            echo "❌ install.sh not found in repository"
        fi
        exit 1
    fi
    
    echo "🎉 Bootstrap completed successfully!"
}

# Run main function with all arguments
main "$@"
