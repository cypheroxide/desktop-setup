#!/bin/bash

# install/11-config-tailscale.sh - Install and configure Tailscale VPN with network binding

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

log "Starting Tailscale installation and configuration..."

# Install Tailscale
if gum confirm "Install Tailscale?"; then
    log "Installing Tailscale..."
    
    # Install from AUR (tailscale package)
    if command -v yay &> /dev/null; then
        yay -S --noconfirm tailscale
    elif command -v paru &> /dev/null; then
        paru -S --noconfirm tailscale
    else
        error "Neither yay nor paru found. Please install an AUR helper first."
        exit 1
    fi
    
    # Enable and start Tailscale service
    log "Enabling and starting Tailscale service..."
    sudo systemctl enable tailscaled
    sudo systemctl start tailscaled
    
    success "Tailscale installed and service started"
else
    log "Skipping Tailscale installation"
fi

# Check if Tailscale is already authenticated
if command -v tailscale &> /dev/null; then
    TAILSCALE_STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")
    
    case $TAILSCALE_STATUS in
        "Running")
            success "Tailscale is already authenticated and running"
            CURRENT_IP=$(tailscale ip -4 2>/dev/null || echo "Not available")
            CURRENT_HOSTNAME=$(tailscale status --json 2>/dev/null | jq -r '.Self.HostName' 2>/dev/null || echo "unknown")
            log "Current Tailscale IP: $CURRENT_IP"
            log "Current hostname: $CURRENT_HOSTNAME"
            ;;
        "NeedsLogin"|"Stopped"|"unknown")
            log "Tailscale needs authentication"
            
            if gum confirm "Authenticate with Tailscale now?"; then
                log "Starting Tailscale authentication..."
                
                # Get custom hostname for this device
                SUGGESTED_HOSTNAME=$(hostname 2>/dev/null || echo "aurumOS")
                CUSTOM_HOSTNAME=$(gum input --placeholder="Enter hostname for this device" --value="$SUGGESTED_HOSTNAME")
                
                # Configure Tailscale with custom settings
                log "Configuring Tailscale with hostname: $CUSTOM_HOSTNAME"
                
                # Basic tailscale up with hostname
                if gum confirm "Use advanced Tailscale configuration? (SSH, exit node, etc.)"; then
                    # Advanced configuration options
                    TAILSCALE_FLAGS="--hostname=$CUSTOM_HOSTNAME"
                    
                    if gum confirm "Enable SSH access through Tailscale?"; then
                        TAILSCALE_FLAGS="$TAILSCALE_FLAGS --ssh"
                    fi
                    
                    if gum confirm "Accept DNS configuration from Tailscale?"; then
                        TAILSCALE_FLAGS="$TAILSCALE_FLAGS --accept-dns"
                    fi
                    
                    if gum confirm "Enable this device as exit node?"; then
                        TAILSCALE_FLAGS="$TAILSCALE_FLAGS --advertise-exit-node"
                        # Enable IP forwarding for exit node
                        echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
                        echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
                        sudo sysctl -p
                    fi
                    
                    if gum confirm "Accept routes from other devices?"; then
                        TAILSCALE_FLAGS="$TAILSCALE_FLAGS --accept-routes"
                    fi
                    
                    log "Running: sudo tailscale up $TAILSCALE_FLAGS"
                    sudo tailscale up $TAILSCALE_FLAGS
                else
                    # Basic configuration
                    sudo tailscale up --hostname="$CUSTOM_HOSTNAME" --accept-dns
                fi
                
                # Check if authentication was successful
                sleep 3
                NEW_STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")
                if [[ "$NEW_STATUS" == "Running" ]]; then
                    success "Tailscale authentication successful!"
                    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not available")
                    log "Tailscale IP: $TAILSCALE_IP"
                    log "Device hostname: $CUSTOM_HOSTNAME"
                else
                    error "Tailscale authentication may have failed. Current status: $NEW_STATUS"
                fi
            else
                warn "Tailscale authentication skipped. You can authenticate later using: sudo tailscale up"
            fi
            ;;
        *)
            warn "Tailscale is in an unknown state: $TAILSCALE_STATUS"
            ;;
    esac
else
    error "Tailscale is not installed or not in PATH"
    exit 1
fi

# Configure DNS and network settings
if gum confirm "Configure advanced DNS and network settings?"; then
    log "Configuring DNS and network settings..."
    
    # Create systemd-resolved configuration for Tailscale
    log "Configuring systemd-resolved for Tailscale DNS..."
    sudo mkdir -p /etc/systemd/resolved.conf.d
    
    cat << 'EOF' | sudo tee /etc/systemd/resolved.conf.d/tailscale.conf > /dev/null
[Resolve]
DNS=100.100.100.100
Domains=~ts.net
EOF
    
    # Restart systemd-resolved
    sudo systemctl restart systemd-resolved
    
    # Configure NetworkManager to work with Tailscale
    if systemctl is-active --quiet NetworkManager; then
        log "Configuring NetworkManager for Tailscale..."
        sudo mkdir -p /etc/NetworkManager/conf.d
        
        cat << 'EOF' | sudo tee /etc/NetworkManager/conf.d/tailscale.conf > /dev/null
[main]
dns=systemd-resolved

[connection]
connection.dns-priority=100
EOF
        
        sudo systemctl restart NetworkManager
    fi
    
    success "DNS and network settings configured"
fi

# Configure container and service binding
if gum confirm "Configure containers and services to bind to Tailscale interface?"; then
    log "Configuring container and service binding..."
    
    # Create systemd drop-in directory for Docker
    sudo mkdir -p /etc/systemd/system/docker.service.d
    
    # Create Docker service override for Tailscale
    cat << 'EOF' | sudo tee /etc/systemd/system/docker.service.d/tailscale.conf > /dev/null
[Service]
# Wait for Tailscale to be ready before starting Docker
ExecStartPre=/bin/bash -c 'while ! tailscale status >/dev/null 2>&1; do sleep 1; done'
# Add Tailscale network interface to Docker daemon
ExecStartPre=/bin/bash -c 'TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo ""); if [ -n "$TAILSCALE_IP" ]; then echo "Tailscale IP: $TAILSCALE_IP"; fi'
EOF
    
    # Update Docker daemon configuration to listen on Tailscale interface
    if [ -f /etc/docker/daemon.json ]; then
        log "Updating existing Docker daemon configuration..."
        # Backup existing config
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
        
        # Add Tailscale configuration
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
        if [ -n "$TAILSCALE_IP" ]; then
            sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "hosts": [
    "unix:///var/run/docker.sock",
    "tcp://$TAILSCALE_IP:2376"
  ],
  "tls": false,
  "insecure-registries": ["$TAILSCALE_IP:5000"]
}
EOF
        fi
    fi
    
    # Create script to get Tailscale IP for container configurations
    sudo mkdir -p /usr/local/bin
    cat << 'EOF' | sudo tee /usr/local/bin/get-tailscale-ip > /dev/null
#!/bin/bash
# Get current Tailscale IP address
tailscale ip -4 2>/dev/null || echo "127.0.0.1"
EOF
    sudo chmod +x /usr/local/bin/get-tailscale-ip
    
    # Create environment file for Tailscale variables
    sudo mkdir -p /etc/tailscale
    cat << 'EOF' | sudo tee /etc/tailscale/environment > /dev/null
# Tailscale environment variables for services
# Source this file in your service configurations
export TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "127.0.0.1")
export TAILSCALE_HOSTNAME=$(tailscale status --json 2>/dev/null | jq -r '.Self.HostName' 2>/dev/null || hostname)
EOF
    
    # Create systemd service to update Tailscale environment on network changes
    cat << 'EOF' | sudo tee /etc/systemd/system/tailscale-env-update.service > /dev/null
[Unit]
Description=Update Tailscale environment variables
After=tailscaled.service
Requires=tailscaled.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "127.0.0.1")" > /etc/tailscale/environment; echo "TAILSCALE_HOSTNAME=$(tailscale status --json 2>/dev/null | jq -r ".Self.HostName" 2>/dev/null || hostname)" >> /etc/tailscale/environment'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start the environment update service
    sudo systemctl daemon-reload
    sudo systemctl enable tailscale-env-update.service
    sudo systemctl start tailscale-env-update.service
    
    # Reload Docker daemon
    sudo systemctl daemon-reload
    if systemctl is-active --quiet docker; then
        sudo systemctl restart docker
    fi
    
    success "Container and service binding configured"
fi

# Create Docker Compose template with Tailscale integration
if gum confirm "Create Docker Compose template with Tailscale integration?"; then
    log "Creating Docker Compose template..."
    
    PROJECT_DIR="/run/media/$USER/Data/desktop-setup"
    DOCKER_DIR="$PROJECT_DIR/docker"
    mkdir -p "$DOCKER_DIR/templates"
    
    cat << 'EOF' > "$DOCKER_DIR/templates/tailscale-compose.yml"
version: '3.8'

# Docker Compose template with Tailscale integration
# This template shows how to configure services to work with Tailscale VPN

services:
  # Example web service accessible via Tailscale
  web-service:
    image: nginx:alpine
    container_name: tailscale-web
    restart: unless-stopped
    ports:
      # Bind to Tailscale interface only
      - "${TAILSCALE_IP:-127.0.0.1}:8080:80"
    environment:
      - TAILSCALE_IP=${TAILSCALE_IP:-127.0.0.1}
      - TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-localhost}
    volumes:
      - ./web-content:/usr/share/nginx/html:ro
    networks:
      - tailscale-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.web-service.rule=Host(`${TAILSCALE_HOSTNAME:-localhost}.ts.net`)"
      - "traefik.http.services.web-service.loadbalancer.server.port=80"

  # Example database service accessible only via Tailscale
  database:
    image: postgres:15-alpine
    container_name: tailscale-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=appdb
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD=secure_password
    ports:
      # Bind to Tailscale interface only
      - "${TAILSCALE_IP:-127.0.0.1}:5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - tailscale-network

  # Traefik reverse proxy for Tailscale domains
  traefik:
    image: traefik:v3.0
    container_name: tailscale-traefik
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "${TAILSCALE_IP:-127.0.0.1}:80:80"
      - "${TAILSCALE_IP:-127.0.0.1}:443:443"
      - "${TAILSCALE_IP:-127.0.0.1}:8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - tailscale-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.${TAILSCALE_HOSTNAME:-localhost}.ts.net`)"
      - "traefik.http.routers.traefik.service=api@internal"

networks:
  tailscale-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16

volumes:
  db-data:
EOF
    
    # Create environment file for the template
    cat << 'EOF' > "$DOCKER_DIR/templates/.env.example"
# Tailscale environment variables
# Copy this file to .env and update the values
TAILSCALE_IP=100.64.0.1
TAILSCALE_HOSTNAME=aurumOS

# Application-specific variables
POSTGRES_DB=appdb
POSTGRES_USER=appuser
POSTGRES_PASSWORD=secure_password

# Domain configuration
DOMAIN_SUFFIX=ts.net
EOF
    
    # Create a script to update the environment file
    cat << 'EOF' > "$DOCKER_DIR/templates/update-tailscale-env.sh"
#!/bin/bash
# Update Tailscale environment variables for Docker Compose

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "127.0.0.1")
TAILSCALE_HOSTNAME=$(tailscale status --json 2>/dev/null | jq -r '.Self.HostName' 2>/dev/null || hostname)

echo "TAILSCALE_IP=$TAILSCALE_IP" > .env
echo "TAILSCALE_HOSTNAME=$TAILSCALE_HOSTNAME" >> .env

# Copy other values from .env.example if they exist
if [ -f .env.example ]; then
    grep -v "^TAILSCALE_" .env.example >> .env
fi

echo "Updated .env file with Tailscale IP: $TAILSCALE_IP and hostname: $TAILSCALE_HOSTNAME"
EOF
    chmod +x "$DOCKER_DIR/templates/update-tailscale-env.sh"
    
    success "Docker Compose template created at $DOCKER_DIR/templates/"
fi

# Create Tailscale management scripts
if gum confirm "Create Tailscale management scripts?"; then
    log "Creating Tailscale management scripts..."
    
    BIN_DIR="/home/$USER/.local/bin"
    mkdir -p "$BIN_DIR"
    
    # Enhanced toggle script
    cat << 'EOF' > "$BIN_DIR/tailscale-toggle"
#!/bin/bash
# Enhanced Tailscale toggle script with status display

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    print_error "Tailscale is not installed."
    exit 1
fi

# Get current status
STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")

case $STATUS in
    "Running")
        print_status "Tailscale is running. Current status:"
        tailscale status --self=false 2>/dev/null
        echo
        if gum confirm "Stop Tailscale?"; then
            sudo tailscale down
            print_success "Tailscale stopped"
        fi
        ;;
    "Stopped"|"NeedsLogin"|"unknown")
        print_status "Tailscale is stopped."
        if gum confirm "Start Tailscale?"; then
            sudo tailscale up
            print_success "Tailscale started"
            print_status "Current IP: $(tailscale ip -4 2>/dev/null || echo 'Not available')"
        fi
        ;;
    *)
        print_warning "Tailscale is in an unknown state: $STATUS"
        ;;
esac
EOF
    chmod +x "$BIN_DIR/tailscale-toggle"
    
    # Status script
    cat << 'EOF' > "$BIN_DIR/tailscale-status"
#!/bin/bash
# Tailscale status display script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Tailscale Status ===${NC}"
echo

if command -v tailscale &> /dev/null; then
    STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")
    
    case $STATUS in
        "Running")
            echo -e "${GREEN}Status: Running${NC}"
            echo "IP Address: $(tailscale ip -4 2>/dev/null || echo 'Not available')"
            echo "Hostname: $(tailscale status --json 2>/dev/null | jq -r '.Self.HostName' 2>/dev/null || echo 'unknown')"
            echo
            echo "Connected devices:"
            tailscale status --self=false 2>/dev/null || echo "Unable to get device list"
            ;;
        *)
            echo -e "${GREEN}Status: $STATUS${NC}"
            echo "Use 'tailscale-toggle' to start Tailscale"
            ;;
    esac
else
    echo "Tailscale is not installed"
fi
EOF
    chmod +x "$BIN_DIR/tailscale-status"
    
    # Network info script
    cat << 'EOF' > "$BIN_DIR/tailscale-network-info"
#!/bin/bash
# Display Tailscale network information

echo "=== Tailscale Network Information ==="
echo

if command -v tailscale &> /dev/null; then
    echo "Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'Not available')"
    echo "Tailscale IPv6: $(tailscale ip -6 2>/dev/null || echo 'Not available')"
    echo "Hostname: $(tailscale status --json 2>/dev/null | jq -r '.Self.HostName' 2>/dev/null || echo 'unknown')"
    echo
    
    # Show network interface info
    TAILSCALE_IFACE=$(ip route show | grep -E '100\.64\.' | head -1 | awk '{print $3}' || echo "tailscale0")
    if [ -n "$TAILSCALE_IFACE" ]; then
        echo "Network interface: $TAILSCALE_IFACE"
        echo "Interface details:"
        ip addr show "$TAILSCALE_IFACE" 2>/dev/null || echo "Interface not found"
    fi
    
    echo
    echo "DNS Settings:"
    tailscale status --json 2>/dev/null | jq -r '.DNS.Nameservers[]' 2>/dev/null || echo "No DNS info available"
    
    echo
    echo "Routes:"
    tailscale status --json 2>/dev/null | jq -r '.Route.Routes[]' 2>/dev/null || echo "No route info available"
else
    echo "Tailscale is not installed"
fi
EOF
    chmod +x "$BIN_DIR/tailscale-network-info"
    
    success "Tailscale management scripts created in $BIN_DIR/"
    log "Available commands: tailscale-toggle, tailscale-status, tailscale-network-info"
fi

# Final status check and summary
echo
log "=== Tailscale Configuration Summary ==="

if command -v tailscale &> /dev/null; then
    FINAL_STATUS=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")
    
    case $FINAL_STATUS in
        "Running")
            success "Tailscale is running and configured"
            TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not available")
            TAILSCALE_HOSTNAME=$(tailscale status --json 2>/dev/null | jq -r '.Self.HostName' 2>/dev/null || echo "unknown")
            log "Tailscale IP: $TAILSCALE_IP"
            log "Hostname: $TAILSCALE_HOSTNAME"
            log "Access this device at: $TAILSCALE_HOSTNAME.ts.net"
            ;;
        *)
            warn "Tailscale is installed but not running (Status: $FINAL_STATUS)"
            log "Use 'sudo tailscale up' to authenticate and start"
            ;;
    esac
else
    error "Tailscale installation may have failed"
fi

echo
log "Configuration files created:"
log "  - Docker daemon config: /etc/docker/daemon.json"
log "  - Tailscale environment: /etc/tailscale/environment"
log "  - Docker Compose template: $DOCKER_DIR/templates/tailscale-compose.yml"
log "  - Management scripts: ~/.local/bin/tailscale-*"

echo
log "Next steps:"
log "  1. Restart your session to update PATH for management scripts"
log "  2. Use 'tailscale-status' to check current status"
log "  3. Use 'tailscale-toggle' to start/stop Tailscale"
log "  4. Configure your containers to use Tailscale IP bindings"
log "  5. Test connectivity from other devices on your Tailscale network"

success "Tailscale configuration completed!"
