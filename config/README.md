# Configuration Files

This directory contains sample configuration files and templates for various applications and system components used in the desktop setup.

## Directory Structure

```
config/
├── README.md                    # This file
├── bashrc                       # Bash shell configuration
├── gitconfig                    # Git global configuration
├── gitignore_global            # Global gitignore patterns
├── ssh_config                  # SSH client configuration
├── vscode-settings.json        # VS Code editor settings
├── kde/                        # KDE Plasma configurations
│   ├── kdeglobals              # KDE global settings
│   └── konsolerc               # Konsole terminal settings
├── docker-templates/           # Docker Compose templates
│   ├── media-server-compose.yml
│   └── development-compose.yml
└── flatpak/                    # Flatpak application overrides
    ├── README.md
    ├── obs-studio-overrides.sh
    ├── bottles-overrides.sh
    └── discord-overrides.sh
```

## Installation Instructions

### Shell Configuration

1. **Bash Configuration**:
   ```bash
   cp config/bashrc ~/.bashrc
   source ~/.bashrc
   ```

2. **Git Configuration**:
   ```bash
   cp config/gitconfig ~/.gitconfig
   cp config/gitignore_global ~/.gitignore_global
   
   # Update with your information
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

### SSH Configuration

1. **SSH Client Config**:
   ```bash
   mkdir -p ~/.ssh/sockets
   cp config/ssh_config ~/.ssh/config
   chmod 600 ~/.ssh/config
   
   # Generate SSH key if needed
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

### KDE Configuration

1. **KDE Settings**:
   ```bash
   cp config/kde/kdeglobals ~/.config/kdeglobals
   cp config/kde/konsolerc ~/.config/konsolerc
   
   # Restart KDE services
   kquitapp5 plasmashell && kstart5 plasmashell
   ```

### VS Code Configuration

1. **VS Code Settings**:
   ```bash
   mkdir -p ~/.config/Code/User
   cp config/vscode-settings.json ~/.config/Code/User/settings.json
   ```

### Docker Templates

1. **Media Server Setup**:
   ```bash
   mkdir -p ~/docker/media-server
   cp config/docker-templates/media-server-compose.yml ~/docker/media-server/docker-compose.yml
   cd ~/docker/media-server
   
   # Edit configuration
   nano docker-compose.yml
   
   # Start services
   sudo docker-compose up -d
   ```

2. **Development Environment**:
   ```bash
   mkdir -p ~/docker/development
   cp config/docker-templates/development-compose.yml ~/docker/development/docker-compose.yml
   cd ~/docker/development
   
   # Edit configuration
   nano docker-compose.yml
   
   # Start services
   sudo docker-compose up -d
   ```

### Flatpak Overrides

1. **Apply Flatpak Overrides**:
   ```bash
   # Make scripts executable
   chmod +x config/flatpak/*.sh
   
   # Apply overrides for installed applications
   ./config/flatpak/obs-studio-overrides.sh
   ./config/flatpak/bottles-overrides.sh
   ./config/flatpak/discord-overrides.sh
   ```

## Configuration Details

### Bash Configuration Features

- **Colored prompt** with git branch information
- **Comprehensive aliases** for common commands
- **Docker aliases** with sudo integration
- **Tailscale-specific** aliases and functions
- **Arch Linux** package management shortcuts
- **Development tools** shortcuts

### Git Configuration Features

- **Enhanced logging** with color-coded output
- **Useful aliases** for common workflows
- **Automatic setup** for remote tracking
- **Tailscale network** optimizations
- **Security settings** for signing and credentials

### SSH Configuration Features

- **Tailscale network hosts** pre-configured
- **Connection multiplexing** for performance
- **Security hardening** settings
- **Development server** examples
- **Key management** best practices

### VS Code Configuration Features

- **Editor optimizations** for productivity
- **Language-specific** formatting settings
- **Extension configurations** for common tools
- **Remote development** settings for Tailscale
- **Terminal integration** settings

### Docker Templates

#### Media Server Template
- **Plex Media Server** for media streaming
- **Jellyfin** as alternative media server
- **Sonarr/Radarr** for media management
- **qBittorrent** for downloads
- **Overseerr** for request management
- **Tautulli** for Plex statistics

#### Development Template
- **Database services** (PostgreSQL, MySQL, MongoDB, Redis)
- **Development tools** (Adminer, phpMyAdmin)
- **Runtime environments** (Node.js, Python)
- **Supporting services** (Nginx, MailHog, MinIO)
- **Search and analytics** (Elasticsearch, Kibana)
- **Code Server** for browser-based development

### Flatpak Overrides

- **Expanded permissions** for better functionality
- **File system access** to common directories
- **Hardware access** for audio/video applications
- **Network access** for communication apps

## Customization

### Tailscale Network Integration

All configurations are designed to work seamlessly with Tailscale:

- **SSH configs** include Tailscale hostnames
- **Git settings** optimize for VPN networks
- **Docker services** are accessible via Tailscale
- **Development tools** can be reached from any device

### Hostname Configuration

The configurations reference these Tailscale hostnames:
- `aurumos` - Main workstation
- `eresos` - Personal laptop
- `saeulfr` - Work laptop
- `pi4-router` - Raspberry Pi NAS
- `brokkr` - Plex media server

Update these in the configuration files to match your network.

### Security Considerations

- **SSH keys**: Generate unique keys for different purposes
- **Passwords**: Update default passwords in Docker templates
- **Permissions**: Review and adjust file permissions as needed
- **Firewall**: Configure appropriate firewall rules for services

## Troubleshooting

### Common Issues

1. **SSH Permission Denied**:
   ```bash
   chmod 600 ~/.ssh/config
   chmod 700 ~/.ssh
   ```

2. **Git Authentication Issues**:
   ```bash
   git config --global credential.helper store
   # Or use SSH keys instead of HTTPS
   ```

3. **Docker Permission Denied**:
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

4. **Flatpak Override Not Working**:
   ```bash
   flatpak run --verbose com.example.App
   # Check for permission errors
   ```

### Getting Help

- Check application logs for specific errors
- Review Tailscale connectivity with `tailscale status`
- Test network connectivity with the `network-monitor.sh` script
- Verify file permissions and ownership

## Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [KDE UserBase](https://userbase.kde.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Flatpak Documentation](https://docs.flatpak.org/)
