#!/bin/bash

# install/05-docker-containers.sh
# Docker and Tailscale networking setup for AurumOS Desktop Setup

set -e

echo "=== Docker and Tailscale Networking Setup ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Install Docker and Docker Compose via yay
print_status "Installing Docker and Docker Compose via yay..."
yay -S --noconfirm docker docker-compose

# Create Docker daemon configuration directory
print_status "Creating Docker daemon configuration..."
sudo mkdir -p /etc/docker

# Configure Docker daemon with logging limits
print_status "Configuring Docker daemon logging limits..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# Enable and start Docker service
print_status "Enabling and starting Docker service..."
sudo systemctl enable docker.service
sudo systemctl start docker.service

# Add current user to docker group
print_status "Adding user $USER to docker group..."
sudo usermod -aG docker $USER

# Install Tailscale Docker plugin
print_status "Installing Tailscale Docker plugin..."
sudo docker plugin install tailscale/docker-plugin:latest || print_warning "Tailscale Docker plugin may already be installed"

# Create project directory structure
print_status "Creating project directory structure..."
PROJECT_DIR="/run/media/$USER/Data/desktop-setup"
DOCKER_DIR="$PROJECT_DIR/docker"
mkdir -p "$DOCKER_DIR"/{open-webui,portainer,pipelines}

# Create Docker Compose file for Open WebUI
print_status "Creating Open WebUI Docker Compose configuration..."
cat > "$DOCKER_DIR/open-webui/docker-compose.yml" <<EOF
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
      - WEBUI_SECRET_KEY=your-secret-key-here
    volumes:
      - open-webui-data:/app/backend/data
    network_mode: host  # Use host networking for Tailscale access
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  open-webui-data:
EOF

# Create Docker Compose file for Portainer
print_status "Creating Portainer Docker Compose configuration..."
cat > "$DOCKER_DIR/portainer/docker-compose.yml" <<EOF
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer-data:/data
    network_mode: host  # Use host networking for Tailscale access
    command: -H unix:///var/run/docker.sock

volumes:
  portainer-data:
EOF

# Create Docker Compose file for custom pipelines
print_status "Creating custom pipelines Docker Compose configuration..."
cat > "$DOCKER_DIR/pipelines/docker-compose.yml" <<EOF
version: '3.8'

services:
  pipeline-runner:
    image: python:3.11-slim
    container_name: pipeline-runner
    restart: unless-stopped
    working_dir: /app
    volumes:
      - ./pipelines:/app/pipelines
      - ./logs:/app/logs
      - ./data:/app/data
    environment:
      - PYTHONPATH=/app
      - PIPELINE_ENV=production
    network_mode: host  # Use host networking for Tailscale access
    command: |
      sh -c "
        pip install -r requirements.txt &&
        python -m pipelines.main
      "
    depends_on:
      - redis
      - postgres

  redis:
    image: redis:7-alpine
    container_name: pipeline-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    network_mode: host

  postgres:
    image: postgres:15-alpine
    container_name: pipeline-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=pipelines
      - POSTGRES_USER=pipeline_user
      - POSTGRES_PASSWORD=pipeline_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    network_mode: host

volumes:
  redis-data:
  postgres-data:
EOF

# Create requirements.txt for pipelines
cat > "$DOCKER_DIR/pipelines/requirements.txt" <<EOF
fastapi==0.104.1
uvicorn==0.24.0
redis==5.0.1
psycopg2-binary==2.9.9
celery==5.3.4
requests==2.31.0
pydantic==2.5.0
python-multipart==0.0.6
EOF

# Create pipelines directory structure
mkdir -p "$DOCKER_DIR/pipelines"/{pipelines,logs,data}

# Create a sample pipeline
cat > "$DOCKER_DIR/pipelines/pipelines/main.py" <<EOF
#!/usr/bin/env python3
"""
Custom pipelines main entry point
"""
import os
import time
import logging
from fastapi import FastAPI
from fastapi.responses import JSONResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/pipeline.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

app = FastAPI(title="Custom Pipelines API", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Custom Pipelines API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": time.time()}

@app.get("/pipelines")
async def list_pipelines():
    return {
        "pipelines": [
            {"id": "sample", "name": "Sample Pipeline", "status": "active"},
            {"id": "data-processor", "name": "Data Processor", "status": "inactive"}
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Create deployment script
print_status "Creating deployment script..."
cat > "$DOCKER_DIR/deploy.sh" <<EOF
#!/bin/bash

# Deploy all containers
echo "Deploying Docker containers..."

# Deploy Open WebUI
echo "Starting Open WebUI..."
cd "$DOCKER_DIR/open-webui"
sudo docker-compose up -d

# Deploy Portainer
echo "Starting Portainer..."
cd "$DOCKER_DIR/portainer"
sudo docker-compose up -d

# Deploy Custom Pipelines
echo "Starting Custom Pipelines..."
cd "$DOCKER_DIR/pipelines"
sudo docker-compose up -d

echo "All containers deployed successfully!"
echo ""
echo "Access URLs (via Tailscale):"
echo "  - Open WebUI: http://\$(tailscale ip --4):3000"
echo "  - Portainer: http://\$(tailscale ip --4):9000"
echo "  - Custom Pipelines: http://\$(tailscale ip --4):8000"
echo ""
echo "To check container status: sudo docker ps"
echo "To view logs: sudo docker-compose logs -f [service-name]"
EOF

chmod +x "$DOCKER_DIR/deploy.sh"

# Create maintenance script
print_status "Creating maintenance script..."
cat > "$DOCKER_DIR/maintenance.sh" <<EOF
#!/bin/bash

# Docker maintenance script
echo "Docker Maintenance Script"
echo "========================="

case "\$1" in
    start)
        echo "Starting all containers..."
        cd "$DOCKER_DIR/open-webui" && sudo docker-compose start
        cd "$DOCKER_DIR/portainer" && sudo docker-compose start
        cd "$DOCKER_DIR/pipelines" && sudo docker-compose start
        ;;
    stop)
        echo "Stopping all containers..."
        cd "$DOCKER_DIR/open-webui" && sudo docker-compose stop
        cd "$DOCKER_DIR/portainer" && sudo docker-compose stop
        cd "$DOCKER_DIR/pipelines" && sudo docker-compose stop
        ;;
    restart)
        echo "Restarting all containers..."
        cd "$DOCKER_DIR/open-webui" && sudo docker-compose restart
        cd "$DOCKER_DIR/portainer" && sudo docker-compose restart
        cd "$DOCKER_DIR/pipelines" && sudo docker-compose restart
        ;;
    status)
        echo "Container status:"
        sudo docker ps
        ;;
    logs)
        echo "Recent logs:"
        sudo docker-compose logs --tail=50 -f
        ;;
    cleanup)
        echo "Cleaning up unused Docker resources..."
        sudo docker system prune -f
        sudo docker volume prune -f
        sudo docker network prune -f
        ;;
    update)
        echo "Updating container images..."
        cd "$DOCKER_DIR/open-webui" && sudo docker-compose pull && sudo docker-compose up -d
        cd "$DOCKER_DIR/portainer" && sudo docker-compose pull && sudo docker-compose up -d
        cd "$DOCKER_DIR/pipelines" && sudo docker-compose pull && sudo docker-compose up -d
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|logs|cleanup|update}"
        exit 1
        ;;
esac
EOF

chmod +x "$DOCKER_DIR/maintenance.sh"

# Create Tailscale network configuration script
print_status "Creating Tailscale network configuration..."
cat > "$DOCKER_DIR/tailscale-setup.sh" <<EOF
#!/bin/bash

# Tailscale Docker network setup
echo "Setting up Tailscale Docker networking..."

# Check if Tailscale is running
if ! systemctl is-active --quiet tailscaled; then
    echo "Starting Tailscale daemon..."
    sudo systemctl start tailscaled
    sudo systemctl enable tailscaled
fi

# Get Tailscale IP
TAILSCALE_IP=\$(tailscale ip --4)
if [ -z "\$TAILSCALE_IP" ]; then
    echo "Warning: Tailscale IP not found. Make sure Tailscale is authenticated."
    echo "Run: tailscale up"
    exit 1
fi

echo "Tailscale IP: \$TAILSCALE_IP"

# Configure Docker to use host networking for Tailscale access
echo "Docker containers are configured to use host networking for Tailscale access."
echo "This allows containers to be accessible via the Tailscale network."

# Test connectivity
echo "Testing Tailscale connectivity..."
ping -c 1 \$TAILSCALE_IP && echo "Tailscale connectivity: OK" || echo "Tailscale connectivity: FAILED"

echo "Tailscale setup complete!"
EOF

chmod +x "$DOCKER_DIR/tailscale-setup.sh"

print_status "Docker and Tailscale networking setup complete!"
print_warning "IMPORTANT: You need to log out and log back in for the docker group changes to take effect."
print_status "After relogging, run the following commands to deploy containers:"
print_status "  cd $DOCKER_DIR"
print_status "  ./tailscale-setup.sh"
print_status "  ./deploy.sh"
print_status ""
print_status "Container URLs will be accessible via Tailscale at:"
print_status "  - Open WebUI: http://[tailscale-ip]:3000"
print_status "  - Portainer: http://[tailscale-ip]:9000"
print_status "  - Custom Pipelines: http://[tailscale-ip]:8000"
print_status ""
print_status "Use ./maintenance.sh for container management operations."

echo
echo "=== Setup Complete ==="
echo "Please reboot or log out/in to apply docker group changes."
