#!/bin/bash

# install/02-core-dev-tools.sh - Install core system and development tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
    exit 1
fi

# Check if gum is available
if ! command -v gum &> /dev/null; then
    error "gum is required but not installed. Please install it first."
    exit 1
fi

log "Starting core development tools installation..."

# Update system packages
if gum confirm "Update system packages?"; then
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm
    success "System packages updated"
else
    log "Skipping system package update"
fi

# Core System Tools
if gum confirm "Install core system tools? (base-devel, git, curl, wget, unzip, htop, tree, etc.)"; then
    log "Installing core system tools..."
    sudo pacman -S --noconfirm --needed \
        base-devel \
        git \
        curl \
        wget \
        unzip \
        zip \
        htop \
        tree \
        neofetch \
        man-db \
        man-pages \
        which \
        lsof \
        strace \
        rsync \
        openssh \
        gnupg \
        pass
    success "Core system tools installed"
else
    log "Skipping core system tools installation"
fi

# Development Tools
if gum confirm "Install development tools? (gcc, make, cmake, gdb, etc.)"; then
    log "Installing development tools..."
    sudo pacman -S --noconfirm --needed \
        gcc \
        make \
        cmake \
        gdb \
        valgrind \
        clang \
        lldb \
        ninja \
        meson \
        autoconf \
        automake \
        libtool \
        pkg-config
    success "Development tools installed"
else
    log "Skipping development tools installation"
fi

# Python Development
if gum confirm "Install Python development environment?"; then
    log "Installing Python development tools..."
    sudo pacman -S --noconfirm --needed \
        python \
        python-pip \
        python-setuptools \
        python-wheel \
        python-virtualenv \
        python-pipenv \
        python-poetry \
        python-pytest \
        python-black \
        python-flake8 \
        python-mypy \
        ipython \
        jupyter-notebook
    success "Python development tools installed"
else
    log "Skipping Python development tools installation"
fi

# Node.js Development
if gum confirm "Install Node.js development environment?"; then
    log "Installing Node.js development tools..."
    sudo pacman -S --noconfirm --needed \
        nodejs \
        npm \
        yarn
    
    # Install commonly used global packages
    log "Installing global npm packages..."
    sudo npm install -g \
        typescript \
        @typescript-eslint/parser \
        @typescript-eslint/eslint-plugin \
        eslint \
        prettier \
        nodemon \
        pm2 \
        http-server \
        create-react-app \
        @vue/cli \
        @angular/cli
    success "Node.js development tools installed"
else
    log "Skipping Node.js development tools installation"
fi

# Rust Development
if gum confirm "Install Rust development environment?"; then
    log "Installing Rust development tools..."
    sudo pacman -S --noconfirm --needed \
        rust \
        rust-analyzer \
        cargo
    
    # Install additional Rust tools
    log "Installing additional Rust tools..."
    cargo install \
        rustfmt \
        clippy \
        cargo-watch \
        cargo-edit \
        cargo-tree \
        cargo-audit
    success "Rust development tools installed"
else
    log "Skipping Rust development tools installation"
fi

# Go Development
if gum confirm "Install Go development environment?"; then
    log "Installing Go development tools..."
    sudo pacman -S --noconfirm --needed \
        go \
        go-tools
    success "Go development tools installed"
else
    log "Skipping Go development tools installation"
fi

# Docker and Containerization
if gum confirm "Install Docker and containerization tools?"; then
    log "Installing Docker and containerization tools..."
    sudo pacman -S --noconfirm --needed \
        docker \
        docker-compose \
        podman \
        buildah
    
    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    log "Added $USER to docker group. You may need to log out and back in for changes to take effect."
    success "Docker and containerization tools installed"
else
    log "Skipping Docker and containerization tools installation"
fi

# Database Tools
if gum confirm "Install database tools? (sqlite, postgresql-client, mysql-client, etc.)"; then
    log "Installing database tools..."
    sudo pacman -S --noconfirm --needed \
        sqlite \
        postgresql \
        mariadb \
        redis \
        dbeaver
    success "Database tools installed"
else
    log "Skipping database tools installation"
fi

# Text Editors and IDEs
if gum confirm "Install text editors and development IDEs?"; then
    log "Installing text editors and IDEs..."
    sudo pacman -S --noconfirm --needed \
        vim \
        neovim \
        emacs \
        code \
        sublime-text-4
    success "Text editors and IDEs installed"
else
    log "Skipping text editors and IDEs installation"
fi

# Configure sudoers
if gum confirm "Configure sudoers for passwordless sudo?"; then
    log "Configuring sudoers..."
    
    # Create sudoers file for the current user
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER > /dev/null
    sudo chmod 440 /etc/sudoers.d/$USER
    
    # Validate sudoers file
    if sudo visudo -c -f /etc/sudoers.d/$USER; then
        success "Sudoers configured for passwordless sudo"
    else
        error "Sudoers configuration failed"
        sudo rm -f /etc/sudoers.d/$USER
    fi
else
    log "Skipping sudoers configuration"
fi

# Configure locales
if gum confirm "Configure system locales?"; then
    log "Configuring locales..."
    
    # Uncomment common locales
    sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sudo sed -i 's/^#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
    
    # Generate locales
    sudo locale-gen
    
    # Set system locale
    echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null
    
    success "Locales configured"
else
    log "Skipping locale configuration"
fi

# Configure timezone
if gum confirm "Configure system timezone?"; then
    log "Available timezones:"
    
    # Show common timezones
    timedatectl list-timezones | grep -E "(America|Europe|Asia|Pacific)" | head -20
    
    # Prompt for timezone
    TIMEZONE=$(gum input --placeholder "Enter timezone (e.g., America/New_York, Europe/London, etc.)")
    
    if [[ -n "$TIMEZONE" ]]; then
        if timedatectl list-timezones | grep -q "^$TIMEZONE$"; then
            sudo timedatectl set-timezone "$TIMEZONE"
            success "Timezone set to $TIMEZONE"
        else
            error "Invalid timezone: $TIMEZONE"
        fi
    else
        log "No timezone specified, skipping"
    fi
else
    log "Skipping timezone configuration"
fi

# Configure Git (if installed)
if command -v git &> /dev/null && gum confirm "Configure Git global settings?"; then
    log "Configuring Git..."
    
    GIT_NAME=$(gum input --placeholder "Enter your full name for Git")
    GIT_EMAIL=$(gum input --placeholder "Enter your email for Git")
    
    if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
        git config --global user.name "$GIT_NAME"
        git config --global user.email "$GIT_EMAIL"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.editor "vim"
        success "Git configured"
    else
        log "Git name or email not provided, skipping Git configuration"
    fi
else
    log "Skipping Git configuration"
fi

# Install AUR helper (yay)
if gum confirm "Install AUR helper (yay)?"; then
    log "Installing yay AUR helper..."
    
    if ! command -v yay &> /dev/null; then
        # Clone and build yay
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
        success "yay AUR helper installed"
    else
        log "yay is already installed"
    fi
else
    log "Skipping yay installation"
fi

# Install additional development tools from AUR
if command -v yay &> /dev/null && gum confirm "Install additional development tools from AUR?"; then
    log "Installing additional development tools from AUR..."
    
    yay -S --noconfirm --needed \
        visual-studio-code-bin \
        google-chrome \
        discord \
        slack-desktop \
        postman-bin \
        insomnia \
        dbeaver-ce \
        jetbrains-toolbox
    
    success "Additional development tools installed from AUR"
else
    log "Skipping additional AUR packages"
fi

# Final summary
log "Core development tools installation completed!"
log "Please review the following:"
log "- If Docker was installed, you may need to log out and back in"
log "- Check locale and timezone settings: 'localectl status' and 'timedatectl status'"
log "- Verify Git configuration: 'git config --global --list'"

success "Installation script completed successfully!"
