#!/bin/bash

# install/06-dev-tools-utilities.sh - Install additional developer utilities

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

# Function to confirm actions (fallback if gum is not available)
confirm() {
    local prompt="${1:-Continue?}"
    if command -v gum &> /dev/null; then
        gum confirm "$prompt"
    else
        echo -e "${YELLOW}[CONFIRM]${NC} $prompt (y/N): "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Function to get input (fallback if gum is not available)
get_input() {
    local prompt="${1:-Enter value:}"
    local placeholder="${2:-}"
    if command -v gum &> /dev/null; then
        gum input --placeholder "$placeholder" --prompt "$prompt "
    else
        echo -e "${YELLOW}[INPUT]${NC} $prompt"
        if [[ -n "$placeholder" ]]; then
            echo -e "${BLUE}[HINT]${NC} $placeholder"
        fi
        read -r input
        echo "$input"
    fi
}

log "Starting developer utilities installation..."

# Install gum for better interactive prompts
if ! command -v gum &> /dev/null; then
    if confirm "Install gum for better interactive prompts?"; then
        log "Installing gum..."
        if command -v yay &> /dev/null; then
            yay -S --noconfirm --needed gum
        else
            sudo pacman -S --noconfirm --needed gum
        fi
        success "gum installed"
    else
        log "Skipping gum installation - using fallback prompts"
    fi
fi

# Core Terminal Utilities
if confirm "Install core terminal utilities? (neovim, tmux, htop, etc.)"; then
    log "Installing core terminal utilities..."
    
    # Install from official repos
    sudo pacman -S --noconfirm --needed \
        neovim \
        tmux \
        htop \
        btop \
        fd \
        ripgrep \
        fzf \
        bat \
        eza \
        zoxide \
        starship \
        tree \
        jq \
        yq \
        curl \
        wget \
        rsync \
        unzip \
        zip \
        tar \
        gzip \
        which \
        lsof \
        strace \
        tcpdump \
        nmap \
        netcat \
        socat \
        screen \
        moreutils \
        parallel \
        pv \
        progress \
        ncdu \
        duf \
        dust \
        procs \
        bandwhich \
        bottom \
        tokei \
        hyperfine \
        tealdeer \
        delta \
        difftastic \
        hexyl \
        xh \
        dog \
        sd \
        choose \
        grex \
        rg \
        ag \
        ack
    
    success "Core terminal utilities installed"
else
    log "Skipping core terminal utilities installation"
fi

# Git Tools
if confirm "Install advanced Git tools? (lazygit, git-delta, etc.)"; then
    log "Installing Git tools..."
    
    # Install from official repos
    sudo pacman -S --noconfirm --needed \
        git \
        git-lfs \
        tig \
        git-delta \
        difftastic
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            lazygit \
            gh \
            hub \
            gitui \
            git-absorb \
            git-branchless \
            git-cliff \
            git-trim
    else
        warn "yay not available, skipping AUR Git tools"
    fi
    
    success "Git tools installed"
else
    log "Skipping Git tools installation"
fi

# Development Language Servers and Tools
if confirm "Install language servers and development tools?"; then
    log "Installing language servers and development tools..."
    
    # Language servers and tools from official repos
    sudo pacman -S --noconfirm --needed \
        rust-analyzer \
        gopls \
        typescript-language-server \
        vscode-langservers-extracted \
        yaml-language-server \
        taplo \
        shellcheck \
        shfmt \
        stylua \
        prettier \
        eslint \
        tidy \
        xmllint \
        jq \
        yq \
        pandoc \
        graphviz \
        mermaid-cli \
        plantuml
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            lua-language-server \
            bash-language-server \
            dockerfile-language-server \
            marksman \
            ltex-ls \
            vale-bin \
            hadolint-bin \
            shellharden
    else
        warn "yay not available, skipping AUR language servers"
    fi
    
    success "Language servers and development tools installed"
else
    log "Skipping language servers and development tools installation"
fi

# Python Development Tools
if confirm "Install Python development tools and language servers?"; then
    log "Installing Python development tools..."
    
    sudo pacman -S --noconfirm --needed \
        python \
        python-pip \
        python-pipx \
        python-virtualenv \
        python-poetry \
        python-pytest \
        python-black \
        python-flake8 \
        python-mypy \
        python-pylint \
        python-isort \
        python-autopep8 \
        python-pydocstyle \
        python-rope \
        python-jedi \
        python-language-server \
        python-lsp-server \
        ruff \
        ipython \
        jupyter-notebook
    
    # Install additional Python tools via pipx
    if command -v pipx &> /dev/null; then
        log "Installing Python tools via pipx..."
        pipx install pyright
        pipx install bandit
        pipx install safety
        pipx install pre-commit
        pipx install cookiecutter
        pipx install httpie
        pipx install rich-cli
        pipx install typer-cli
    fi
    
    success "Python development tools installed"
else
    log "Skipping Python development tools installation"
fi

# Node.js Development Tools
if confirm "Install Node.js development tools and language servers?"; then
    log "Installing Node.js development tools..."
    
    sudo pacman -S --noconfirm --needed \
        nodejs \
        npm \
        yarn \
        typescript \
        typescript-language-server \
        vscode-langservers-extracted
    
    # Install global npm packages
    log "Installing global npm packages..."
    sudo npm install -g \
        @typescript-eslint/parser \
        @typescript-eslint/eslint-plugin \
        eslint \
        prettier \
        nodemon \
        pm2 \
        http-server \
        live-server \
        json-server \
        @angular/cli \
        @vue/cli \
        create-react-app \
        create-next-app \
        @nestjs/cli \
        @storybook/cli \
        webpack \
        webpack-cli \
        parcel \
        rollup \
        vite \
        nx \
        lerna \
        rush \
        semantic-release \
        standard-version \
        commitizen \
        cz-conventional-changelog
    
    success "Node.js development tools installed"
else
    log "Skipping Node.js development tools installation"
fi

# Setup nvm (Node Version Manager)
if confirm "Install and setup nvm (Node Version Manager)?"; then
    log "Installing nvm..."
    
    # Download and install nvm
    NVM_VERSION="v0.39.0"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    
    # Source nvm in current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node.js
    if command -v nvm &> /dev/null; then
        log "Installing latest LTS Node.js via nvm..."
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
    fi
    
    success "nvm installed and configured"
else
    log "Skipping nvm installation"
fi

# Setup pyenv (Python Version Manager)
if confirm "Install and setup pyenv (Python Version Manager)?"; then
    log "Installing pyenv..."
    
    # Install pyenv dependencies
    sudo pacman -S --noconfirm --needed \
        base-devel \
        openssl \
        zlib \
        xz \
        tk \
        libffi \
        sqlite
    
    # Install pyenv
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed pyenv
    else
        # Install pyenv manually
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
        
        # Add to shell profile
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        
        # Also add to zshrc if it exists
        if [[ -f ~/.zshrc ]]; then
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
            echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
            echo 'eval "$(pyenv init -)"' >> ~/.zshrc
        fi
    fi
    
    success "pyenv installed and configured"
else
    log "Skipping pyenv installation"
fi

# Rust Development Tools
if confirm "Install Rust development tools?"; then
    log "Installing Rust development tools..."
    
    sudo pacman -S --noconfirm --needed \
        rust \
        rust-analyzer \
        cargo \
        rustfmt \
        clippy
    
    # Install additional Rust tools
    if command -v cargo &> /dev/null; then
        log "Installing additional Rust tools..."
        cargo install \
            cargo-watch \
            cargo-edit \
            cargo-tree \
            cargo-audit \
            cargo-outdated \
            cargo-expand \
            cargo-bloat \
            cargo-geiger \
            cargo-deny \
            cargo-machete \
            cargo-nextest
    fi
    
    success "Rust development tools installed"
else
    log "Skipping Rust development tools installation"
fi

# Go Development Tools
if confirm "Install Go development tools?"; then
    log "Installing Go development tools..."
    
    sudo pacman -S --noconfirm --needed \
        go \
        go-tools \
        gopls \
        delve
    
    # Install additional Go tools
    if command -v go &> /dev/null; then
        log "Installing additional Go tools..."
        go install golang.org/x/tools/cmd/goimports@latest
        go install golang.org/x/tools/cmd/godoc@latest
        go install golang.org/x/tools/cmd/guru@latest
        go install golang.org/x/tools/cmd/gorename@latest
        go install golang.org/x/lint/golint@latest
        go install honnef.co/go/tools/cmd/staticcheck@latest
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        go install github.com/cosmtrek/air@latest
        go install github.com/go-delve/delve/cmd/dlv@latest
    fi
    
    success "Go development tools installed"
else
    log "Skipping Go development tools installation"
fi

# Database Tools
if confirm "Install database development tools?"; then
    log "Installing database tools..."
    
    sudo pacman -S --noconfirm --needed \
        sqlite \
        postgresql \
        mariadb \
        redis \
        mongodb-tools \
        mysql-workbench \
        pgadmin4 \
        sqlitebrowser
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            dbeaver \
            mongodb-compass \
            redis-desktop-manager \
            robo3t-bin
    else
        warn "yay not available, skipping AUR database tools"
    fi
    
    success "Database tools installed"
else
    log "Skipping database tools installation"
fi

# Container and DevOps Tools
if confirm "Install container and DevOps tools?"; then
    log "Installing container and DevOps tools..."
    
    sudo pacman -S --noconfirm --needed \
        docker \
        docker-compose \
        podman \
        buildah \
        skopeo \
        kubectl \
        helm \
        terraform \
        ansible \
        vagrant \
        packer \
        consul \
        nomad \
        vault
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            docker-desktop \
            minikube \
            kind-bin \
            k9s \
            kubectx \
            kustomize \
            skaffold \
            tilt-bin \
            stern-bin \
            dive \
            hadolint-bin \
            trivy-bin \
            grype-bin \
            syft-bin
    else
        warn "yay not available, skipping AUR DevOps tools"
    fi
    
    success "Container and DevOps tools installed"
else
    log "Skipping container and DevOps tools installation"
fi

# Text Processing and Documentation Tools
if confirm "Install text processing and documentation tools?"; then
    log "Installing text processing and documentation tools..."
    
    sudo pacman -S --noconfirm --needed \
        pandoc \
        texlive-core \
        texlive-bin \
        texlive-basic \
        texlive-latex \
        texlive-latexrecommended \
        texlive-latexextra \
        graphviz \
        plantuml \
        mermaid-cli \
        hugo \
        jekyll \
        asciidoc \
        sphinx \
        mdbook \
        vale \
        proselint \
        write-good
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            obsidian \
            typora \
            marktext \
            zettlr \
            logseq-desktop-bin \
            notion-app \
            drawio-desktop-bin \
            marp-cli
    else
        warn "yay not available, skipping AUR documentation tools"
    fi
    
    success "Text processing and documentation tools installed"
else
    log "Skipping text processing and documentation tools installation"
fi

# Monitoring and System Tools
if confirm "Install monitoring and system tools?"; then
    log "Installing monitoring and system tools..."
    
    sudo pacman -S --noconfirm --needed \
        htop \
        btop \
        iotop \
        iftop \
        nethogs \
        nload \
        bmon \
        vnstat \
        sysstat \
        glances \
        ctop \
        ncdu \
        duf \
        dust \
        procs \
        bandwhich \
        bottom \
        zenith \
        zellij \
        tmux \
        screen \
        byobu
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            gotop \
            bashtop \
            s-tui \
            gpu-viewer \
            mission-center \
            resources
    else
        warn "yay not available, skipping AUR monitoring tools"
    fi
    
    success "Monitoring and system tools installed"
else
    log "Skipping monitoring and system tools installation"
fi

# Network Tools
if confirm "Install network development tools?"; then
    log "Installing network tools..."
    
    sudo pacman -S --noconfirm --needed \
        nmap \
        netcat \
        socat \
        tcpdump \
        wireshark-qt \
        mtr \
        traceroute \
        whois \
        dig \
        nslookup \
        curl \
        wget \
        httpie \
        xh \
        hey \
        wrk \
        ab \
        siege \
        ngrok \
        caddy \
        nginx \
        apache
    
    # Install from AUR if yay is available
    if command -v yay &> /dev/null; then
        yay -S --noconfirm --needed \
            postman-bin \
            insomnia \
            hurl \
            bruno-bin \
            proxyman \
            charles-proxy
    else
        warn "yay not available, skipping AUR network tools"
    fi
    
    success "Network tools installed"
else
    log "Skipping network tools installation"
fi

# Optional: Setup shell enhancements
if confirm "Setup shell enhancements? (oh-my-zsh, powerlevel10k, etc.)"; then
    log "Setting up shell enhancements..."
    
    # Install zsh if not already installed
    sudo pacman -S --noconfirm --needed zsh zsh-completions
    
    # Install oh-my-zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install powerlevel10k theme
    if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
    fi
    
    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search 2>/dev/null || true
    
    success "Shell enhancements installed"
else
    log "Skipping shell enhancements installation"
fi

# Final summary
log "Developer utilities installation completed!"
log "Please review the following:"
log "- If nvm was installed, restart your terminal or run: source ~/.bashrc"
log "- If pyenv was installed, restart your terminal or run: source ~/.bashrc"
log "- If oh-my-zsh was installed, consider changing your default shell: chsh -s /bin/zsh"
log "- Some tools may require additional configuration"
log "- Language servers are installed but may need editor/IDE configuration"

success "Installation script completed successfully!"
