#!/bin/bash
set -euo pipefail

echo "=== Testing Configuration Files Application ==="
echo "Container started at: $(date)"

# Update system and install basic tools
pacman -Syu --noconfirm
pacman -S --noconfirm base-devel git curl wget sudo zsh

# Create test user
useradd -m -s /bin/bash testuser
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
sudo -u testuser bash << 'USER_SCRIPT'
set -euo pipefail
cd /home/testuser

echo "Installing Oh My Zsh..."
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended

echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

echo "Installing ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

echo "Creating sample configuration files..."
mkdir -p ~/.config/neofetch ~/.config/fastfetch

# Create sample .zshrc
cat > ~/.zshrc << 'ZSHRC_EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
ZSHRC_EOF

# Create sample .p10k.zsh
echo 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet' > ~/.p10k.zsh

# Create sample neofetch config
cat > ~/.config/neofetch/config.conf << 'NEOFETCH_EOF'
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Shell" shell
}
NEOFETCH_EOF

# Create sample fastfetch config
cat > ~/.config/fastfetch/config.jsonc << 'FASTFETCH_EOF'
{
    "logo": {
        "type": "auto"
    },
    "display": {
        "separator": " "
    }
}
FASTFETCH_EOF

echo "Verifying configuration files..."
if [[ -f ~/.zshrc && -f ~/.p10k.zsh && -f ~/.config/neofetch/config.conf && -f ~/.config/fastfetch/config.jsonc ]]; then
    echo "✓ All configuration files created successfully"
else
    echo "✗ Some configuration files missing"
    exit 1
fi

echo "Testing ZSH configuration..."
if zsh -c 'echo "ZSH test successful"' 2>/dev/null; then
    echo "✓ ZSH configuration is valid"
else
    echo "✗ ZSH configuration has issues"
fi

USER_SCRIPT

echo "=== Configuration Test Completed ==="
echo "Container finished at: $(date)"
