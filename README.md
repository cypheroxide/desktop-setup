# Desktop Setup

## Status Badges

[![CI/CD Pipeline](https://github.com/cypheroxide/desktop-setup/workflows/CI%2FCD%20Pipeline/badge.svg?branch=main)](https://github.com/cypheroxide/desktop-setup/actions/workflows/ci.yml)
[![ShellCheck](https://github.com/cypheroxide/desktop-setup/workflows/CI%2FCD%20Pipeline/badge.svg?branch=main&event=push)](https://github.com/cypheroxide/desktop-setup/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Technology Stack

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff)](https://archlinux.org/)
[![Shell Script](https://img.shields.io/badge/Shell_Script-121011?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![KDE](https://img.shields.io/badge/KDE-1d99f3?logo=kde&logoColor=white)](https://kde.org/)
[![Tailscale](https://img.shields.io/badge/Tailscale-000000?logo=tailscale&logoColor=white)](https://tailscale.com/)

Automated Arch Linux desktop environment setup with KDE Plasma, Tailscale VPN integration, and comprehensive development tools. This project provides a unified bootstrap and installation workflow for setting up a complete desktop workstation.

## Features

- **Unified Bootstrap Process**: Single-command setup with interactive prompts
- **AUR Helper Selection**: Choose between `yay`, `paru`, or `trizen`
- **Modular Installation**: Organized installation scripts for different components
- **KDE Plasma Desktop**: Complete desktop environment with customizations
- **Tailscale VPN Integration**: Automatic VPN setup with container binding
- **Development Tools**: Comprehensive development environment setup
- **Docker Integration**: Pre-configured containers for media and development
- **Configuration Management**: Centralized configuration files and templates

## Project Structure

```
desktop-setup/
├── README.md                    # This documentation
├── bootstrap.sh                 # Bootstrap script with error handling
├── install.sh                   # Main installation orchestrator
├── bin/                         # Custom utilities and helper scripts
│   ├── backup-config.sh         # Configuration backup utility
│   ├── docker-manager.sh        # Docker container management
│   ├── network-monitor.sh       # Network monitoring tools
│   ├── system-update.sh         # System update automation
│   └── toggle-tailscale.sh      # Tailscale VPN toggle
├── config/                      # Configuration files and templates
│   ├── README.md                # Configuration documentation
│   ├── bashrc                   # Bash shell configuration
│   ├── zshrc                    # ZSH shell configuration
│   ├── gitconfig                # Git global configuration
│   ├── ssh_config               # SSH client configuration
│   ├── kde/                     # KDE Plasma configurations
│   ├── docker-templates/        # Docker Compose templates
│   ├── flatpak/                 # Flatpak application overrides
│   ├── neofetch/                # System information display
│   ├── fastfetch/               # Fast system information
│   └── p10k/                    # Powerlevel10k theme configuration
└── install/                     # Modular installation scripts
    ├── 00-chaotic-aur.sh        # Chaotic AUR repository setup
    ├── 01-yay.sh                # AUR helper installation
    ├── 02-core-dev-tools.sh     # Core development tools
    ├── 03-kde-plasma.sh         # KDE Plasma desktop
    ├── 04-flatpaks.sh           # Flatpak applications
    ├── 05-docker-containers.sh  # Docker setup and containers
    ├── 06-dev-tools-utilities.sh # Development utilities
    ├── 07-system-config-themes.sh # System theming
    ├── 08-config-zsh.sh         # ZSH shell configuration
    ├── 09-config-neofetch.sh    # Neofetch configuration
    ├── 10-config-fastfetch.sh   # Fastfetch configuration
    └── 11-config-tailscale.sh   # Tailscale VPN setup
```

## Quick Start

### 1. Bootstrap Installation

Run the bootstrap script to initialize the setup process:

```bash
# Clone the repository (if not already present)
git clone https://github.com/cypheroxide/desktop-setup.git ~/.local/share/desktop-setup
cd ~/.local/share/desktop-setup

# Run bootstrap script
./bootstrap.sh
```

The bootstrap script will:
- Check system requirements
- Install dependencies (git, gum)
- Make scripts executable
- Launch the main installation

### 2. Manual Installation

Alternatively, run the installation script directly:

```bash
./install.sh [OPTIONS]
```

## AUR Helper Selection

The installation process supports multiple AUR helpers. Choose the one that best fits your needs:

### Available AUR Helpers

| Helper | Description | Language | Features |
|--------|-------------|----------|----------|
| **yay** | Feature-rich AUR helper (default) | Go | PKGBUILD viewing, dependency resolution, git support |
| **paru** | Modern AUR helper with advanced features | Rust | News checking, PKGBUILD diffs, upgrade previews |
| **trizen** | Lightweight AUR helper | Perl | Simple interface, basic functionality |

### Selection Methods

1. **Interactive Selection** (default):
   ```bash
   ./install.sh
   # Follow the interactive prompts
   ```

2. **Command Line Option**:
   ```bash
   ./install.sh --aur-helper paru
   ./install.sh -a yay
   ```

3. **Environment Variable**:
   ```bash
   export AUR_HELPER=paru
   ./install.sh
   ```

## Installation Options

### Command Line Arguments

```bash
./install.sh [OPTIONS]

Options:
  -a, --aur-helper HELPER    Choose AUR helper: yay, paru, trizen (default: yay)
  -d, --dry-run              Show what would be installed without actually installing
  -v, --verbose              Enable verbose output
  -h, --help                 Show help message
```

### Examples

```bash
# Install with paru AUR helper
./install.sh --aur-helper paru

# Dry run to see what would be installed
./install.sh --dry-run

# Verbose installation with yay
./install.sh --aur-helper yay --verbose
```

## Installation Modules

The installation process is divided into modular scripts that run in sequence:

### Core System Setup
- **00-chaotic-aur.sh**: Chaotic AUR repository for pre-built packages
- **01-yay.sh**: AUR helper installation and configuration
- **02-core-dev-tools.sh**: Essential development tools (git, vim, etc.)

### Desktop Environment
- **03-kde-plasma.sh**: KDE Plasma desktop with SDDM display manager
- **04-flatpaks.sh**: Flatpak applications (browsers, media, productivity)
- **07-system-config-themes.sh**: System theming and appearance

### Development Environment
- **05-docker-containers.sh**: Docker setup with pre-configured containers
- **06-dev-tools-utilities.sh**: Development utilities and IDEs

### Shell and System Configuration
- **08-config-zsh.sh**: ZSH shell with Powerlevel10k theme
- **09-config-neofetch.sh**: System information display
- **10-config-fastfetch.sh**: Fast system information tool
- **11-config-tailscale.sh**: Tailscale VPN with container integration

## Configuration Management

Configuration files are organized in the `config/` directory and can be applied automatically or manually.

### Automatic Configuration

Most configurations are applied automatically during installation:
- Shell configurations (bash, zsh)
- Git settings and aliases
- KDE Plasma desktop settings
- Docker container templates

### Manual Configuration

Some configurations may require manual setup:
- SSH keys and configurations
- Personal Git credentials
- Application-specific settings

Refer to [`config/README.md`](config/README.md) for detailed configuration instructions.

## Troubleshooting

### Common Issues

#### Arch Linux Issues

1. **Package conflicts during installation**:
   ```bash
   # Remove conflicting packages
   sudo pacman -Rns package-name
   
   # Clear package cache
   sudo pacman -Scc
   
   # Update system before installation
   sudo pacman -Syu
   ```

2. **AUR helper installation fails**:
   ```bash
   # Ensure base-devel is installed
   sudo pacman -S --needed base-devel
   
   # Check for conflicting AUR helpers
   pacman -Qs yay paru trizen
   
   # Remove old AUR helpers before installing new ones
   sudo pacman -Rns old-aur-helper
   ```

3. **Keyring issues**:
   ```bash
   # Update archlinux-keyring
   sudo pacman -S archlinux-keyring
   
   # Reset keyring if corrupted
   sudo rm -rf /etc/pacman.d/gnupg
   sudo pacman-key --init
   sudo pacman-key --populate archlinux
   ```

#### KDE Plasma Issues

1. **Desktop not starting after installation**:
   ```bash
   # Check SDDM status
   sudo systemctl status sddm
   
   # Restart display manager
   sudo systemctl restart sddm
   
   # Check for conflicting display managers
   sudo systemctl list-units --type=service | grep -i display
   ```

2. **Plasma shell crashes**:
   ```bash
   # Restart plasma shell
   kquitapp5 plasmashell && kstart5 plasmashell
   
   # Reset plasma configuration
   rm -rf ~/.config/plasma*
   rm -rf ~/.local/share/plasma*
   ```

3. **KDE applications not theming correctly**:
   ```bash
   # Apply KDE configuration
   cp config/kde/* ~/.config/
   
   # Restart KDE session
   qdbus org.kde.ksmserver /KSMServer logout 0 0 0
   ```

#### Tailscale Issues

1. **Tailscale authentication fails**:
   ```bash
   # Check Tailscale status
   tailscale status
   
   # Re-authenticate
   sudo tailscale up --auth-key YOUR_AUTH_KEY
   
   # Check service status
   sudo systemctl status tailscaled
   ```

2. **Container services not accessible via Tailscale**:
   ```bash
   # Check Tailscale IP
   tailscale ip -4
   
   # Verify Docker daemon configuration
   sudo docker system info | grep -A 5 "Server:"
   
   # Restart Docker with Tailscale dependency
   sudo systemctl restart docker
   ```

3. **DNS resolution issues**:
   ```bash
   # Check systemd-resolved status
   sudo systemctl status systemd-resolved
   
   # Test DNS resolution
   nslookup example.ts.net 100.100.100.100
   
   # Restart DNS services
   sudo systemctl restart systemd-resolved
   ```

### Debug Commands

```bash
# Check system information
neofetch
fastfetch

# Monitor system resources
htop
iotop

# Check network connectivity
ping -c 4 8.8.8.8
tailscale status

# Check service logs
sudo journalctl -u tailscaled -f
sudo journalctl -u sddm -f
sudo journalctl -u docker -f

# Check package installation
pacman -Qs package-name
yay -Qs package-name
```

### Getting Help

1. **Check logs**: Most installation modules provide detailed logging
2. **Review documentation**: Each module has specific documentation
3. **Check system status**: Use provided utility scripts in `bin/`
4. **Verify configuration**: Compare with templates in `config/`

## Customization

### Adding New Modules

To add a new installation module:

1. Create a new script in `install/` with appropriate numbering:
   ```bash
   touch install/12-custom-module.sh
   chmod +x install/12-custom-module.sh
   ```

2. Follow the existing module structure:
   ```bash
   #!/bin/bash
   # Custom Module Description
   set -e
   
   # Your installation logic here
   ```

3. The module will be automatically included in the installation process

### Customizing Configurations

1. **Edit configuration files** in `config/` directory
2. **Add new configurations** following the existing structure
3. **Update documentation** in `config/README.md`

### Environment-Specific Customization

The setup is designed for Tailscale network environments:
- Main workstation: `your.tailscale.domain`
- Tailscale VPN integration for all services
- Docker containers accessible via VPN
- Development tools optimized for remote access

## Contributing

1. **Add new installation modules** to the `install/` directory
2. **Include configuration files** in the `config/` directory
3. **Update documentation** for new features
4. **Test on clean Arch Linux installation**
5. **Follow existing coding patterns** and error handling

## License

This project is open source. Please review individual software licenses for installed components.

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment with comprehensive testing:

### Automated Testing

- **ShellCheck Linting**: All shell scripts are automatically linted with ShellCheck
- **Configuration Validation**: Project structure and config files are validated
- **Non-Interactive Installation**: Tests run in Docker containers mimicking Arch Linux
- **Security Scanning**: Automated checks for hardcoded secrets and unsafe practices
- **Integration Testing**: Validates script dependencies and error handling

### Local Testing

You can run the CI/CD pipeline locally using the provided test script:

```bash
# Run all tests
./test-ci-local.sh

# Run specific test suites
./test-ci-local.sh --shellcheck-only
./test-ci-local.sh --config-only
./test-ci-local.sh --docker-only
./test-ci-local.sh --security-only
./test-ci-local.sh --integration-only

# Show help
./test-ci-local.sh --help
```

### Docker Testing

The project includes a specialized Dockerfile for CI testing:

```bash
# Build test container
sudo docker build -f Dockerfile.ci -t desktop-setup-test .

# Run environment validation
sudo docker run --rm desktop-setup-test /home/testuser/validate-environment.sh

# Run installation tests
sudo docker run --rm desktop-setup-test /home/testuser/test-installation.sh
```

### Pipeline Triggers

- **Push Events**: Runs on pushes to `main`, `master`, and `develop` branches
- **Pull Requests**: Validates all PRs before merging
- **Weekly Schedule**: Runs every Sunday at 2 AM UTC for dependency updates
- **Manual Trigger**: Can be triggered manually from GitHub Actions tab

### Status Badges

The status badges at the top of this README automatically update based on the latest CI/CD run results. They provide quick visual feedback on:

- Overall pipeline status
- ShellCheck linting results
- License compliance
- Technology stack compatibility

## Support

For issues specific to this setup:
1. Check the troubleshooting section above
2. Review module-specific documentation
3. Check system logs for error details
4. Verify Tailscale connectivity and configuration
5. Review CI/CD pipeline results for automated validation
