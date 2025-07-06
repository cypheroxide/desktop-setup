# Tailscale Configuration Module (11-config-tailscale.sh)

This module installs and configures Tailscale VPN with comprehensive network binding for containers and services on AurumOS.

## Features

### 1. Tailscale Installation
- Installs Tailscale from AUR using `yay` or `paru`
- Enables and starts the `tailscaled` service
- Handles authentication with interactive prompts

### 2. Authentication & Configuration
- Supports custom hostname configuration
- Advanced configuration options:
  - SSH access through Tailscale
  - DNS configuration acceptance
  - Exit node capabilities
  - Route acceptance from other devices
- Basic and advanced configuration modes

### 3. DNS & Network Settings
- Configures `systemd-resolved` for Tailscale DNS (100.100.100.100)
- Sets up `.ts.net` domain resolution
- Configures NetworkManager integration
- Ensures proper DNS priority handling

### 4. Container & Service Binding
- Configures Docker to wait for Tailscale before starting
- Updates Docker daemon to listen on Tailscale interface
- Creates systemd service to update Tailscale environment variables
- Provides helper script (`get-tailscale-ip`) for container configurations

### 5. Docker Compose Integration
- Creates comprehensive Docker Compose template with Tailscale integration
- Includes examples for:
  - Web services bound to Tailscale IP
  - Database services accessible only via Tailscale
  - Traefik reverse proxy for `.ts.net` domains
- Automatic environment variable updates

### 6. Management Scripts
Creates utility scripts in `~/.local/bin/`:
- `tailscale-toggle`: Enhanced start/stop functionality with status display
- `tailscale-status`: Comprehensive status information
- `tailscale-network-info`: Detailed network interface and routing information

## Files Created

### System Configuration
- `/etc/systemd/resolved.conf.d/tailscale.conf` - DNS configuration
- `/etc/NetworkManager/conf.d/tailscale.conf` - NetworkManager integration
- `/etc/systemd/system/docker.service.d/tailscale.conf` - Docker service override
- `/etc/docker/daemon.json` - Updated Docker daemon config
- `/etc/tailscale/environment` - Tailscale environment variables
- `/etc/systemd/system/tailscale-env-update.service` - Environment update service

### Utilities
- `/usr/local/bin/get-tailscale-ip` - Helper script for getting Tailscale IP
- `~/.local/bin/tailscale-toggle` - Enhanced toggle script
- `~/.local/bin/tailscale-status` - Status display script
- `~/.local/bin/tailscale-network-info` - Network information script

### Templates
- `$PROJECT_DIR/docker/templates/tailscale-compose.yml` - Docker Compose template
- `$PROJECT_DIR/docker/templates/.env.example` - Environment variables example
- `$PROJECT_DIR/docker/templates/update-tailscale-env.sh` - Environment update script

## Usage

### Running the Module
The module is automatically executed as part of the installation sequence:
```bash
./installv2.sh
```

Or run individually:
```bash
./install/11-config-tailscale.sh
```

### Post-Installation Commands
```bash
# Check Tailscale status
tailscale-status

# Toggle Tailscale on/off
tailscale-toggle

# View network information
tailscale-network-info

# Get current Tailscale IP
get-tailscale-ip
```

### Container Configuration
Use the provided template or configure your own containers:
```bash
cd /run/media/$USER/Data/desktop-setup/docker/templates
cp tailscale-compose.yml ../my-project/
cd ../my-project
./update-tailscale-env.sh
docker-compose up -d
```

## Tailscale Network Access

After configuration, your services will be accessible via:
- **Direct IP**: Use the Tailscale IP (e.g., `100.x.x.x`)
- **Hostname**: Use the device hostname on `.ts.net` domain (e.g., `aurumOS.ts.net`)
- **Service-specific**: Custom domain routing through Traefik

## Security Considerations

- All container services are bound to the Tailscale interface only
- No services are exposed on public interfaces
- DNS resolution is handled securely through Tailscale's infrastructure
- SSH access is optional and controlled through Tailscale ACLs

## Troubleshooting

### Common Issues
1. **Authentication fails**: Ensure you have a Tailscale account and proper network connectivity
2. **Container binding issues**: Verify Tailscale is running before starting Docker services
3. **DNS resolution problems**: Check systemd-resolved configuration and restart if needed

### Debug Commands
```bash
# Check Tailscale service status
sudo systemctl status tailscaled

# View Tailscale logs
sudo journalctl -u tailscaled -f

# Test DNS resolution
nslookup example.ts.net 100.100.100.100

# Check Docker daemon configuration
sudo docker system info | grep -A 10 "Server:"
```

## Integration with AurumOS Rules

This module is designed specifically for the AurumOS Tailscale network environment and integrates with:
- Main workstation hostname configuration
- VPN accessibility requirements for all services
- Docker container management with `sudo` usage patterns
- Project directory structure at `/run/media/$USER/Data/project-heimdal`

The configuration ensures all containers and applications are accessible via the Tailscale VPN as required by the user's network setup.
