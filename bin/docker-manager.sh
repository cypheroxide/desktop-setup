#!/bin/bash
# docker-manager.sh - Docker container management script
# Usage: ./docker-manager.sh [command] [options]

set -e

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

# Set up error handling
setup_error_handling

# Override print_header to use DOCKER prefix
print_header() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] DOCKER:${NC} $1"
}

# Check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! sudo docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status     Show container status"
    echo "  start      Start containers"
    echo "  stop       Stop containers"
    echo "  restart    Restart containers"
    echo "  logs       Show container logs"
    echo "  cleanup    Clean up unused containers, networks, and volumes"
    echo "  stats      Show container resource usage"
    echo "  backup     Backup container volumes"
    echo "  update     Update container images"
    echo ""
    echo "Options:"
    echo "  -c, --container NAME    Target specific container"
    echo "  -a, --all              Apply to all containers"
    echo "  -f, --follow           Follow log output"
    echo "  -h, --help             Show this help message"
}

# Parse command line arguments
COMMAND=""
CONTAINER=""
ALL_CONTAINERS=false
FOLLOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        status|start|stop|restart|logs|cleanup|stats|backup|update)
            COMMAND="$1"
            shift
            ;;
        -c|--container)
            CONTAINER="$2"
            shift 2
            ;;
        -a|--all)
            ALL_CONTAINERS=true
            shift
            ;;
        -f|--follow)
            FOLLOW_LOGS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    show_usage
    exit 1
fi

# Check Docker
check_docker

# Container management functions
show_status() {
    print_header "Container Status"
    if [ -n "$CONTAINER" ]; then
        sudo docker ps -a --filter "name=$CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        sudo docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
}

start_containers() {
    print_header "Starting Containers"
    if [ -n "$CONTAINER" ]; then
        print_status "Starting container: $CONTAINER"
        sudo docker start "$CONTAINER"
    elif [ "$ALL_CONTAINERS" = true ]; then
        print_status "Starting all containers"
        sudo docker start $(sudo docker ps -aq)
    else
        print_error "Please specify a container name or use --all"
        exit 1
    fi
}

stop_containers() {
    print_header "Stopping Containers"
    if [ -n "$CONTAINER" ]; then
        print_status "Stopping container: $CONTAINER"
        sudo docker stop "$CONTAINER"
    elif [ "$ALL_CONTAINERS" = true ]; then
        print_status "Stopping all containers"
        sudo docker stop $(sudo docker ps -q)
    else
        print_error "Please specify a container name or use --all"
        exit 1
    fi
}

restart_containers() {
    print_header "Restarting Containers"
    if [ -n "$CONTAINER" ]; then
        print_status "Restarting container: $CONTAINER"
        sudo docker restart "$CONTAINER"
    elif [ "$ALL_CONTAINERS" = true ]; then
        print_status "Restarting all containers"
        sudo docker restart $(sudo docker ps -q)
    else
        print_error "Please specify a container name or use --all"
        exit 1
    fi
}

show_logs() {
    print_header "Container Logs"
    if [ -n "$CONTAINER" ]; then
        if [ "$FOLLOW_LOGS" = true ]; then
            print_status "Following logs for container: $CONTAINER"
            sudo docker logs -f "$CONTAINER"
        else
            print_status "Showing logs for container: $CONTAINER"
            sudo docker logs --tail 100 "$CONTAINER"
        fi
    else
        print_error "Please specify a container name"
        exit 1
    fi
}

cleanup_docker() {
    print_header "Docker Cleanup"
    print_status "Removing stopped containers..."
    sudo docker container prune -f
    
    print_status "Removing unused networks..."
    sudo docker network prune -f
    
    print_status "Removing unused volumes..."
    sudo docker volume prune -f
    
    print_status "Removing unused images..."
    sudo docker image prune -f
    
    print_status "Cleanup completed"
}

show_stats() {
    print_header "Container Resource Usage"
    if [ -n "$CONTAINER" ]; then
        sudo docker stats "$CONTAINER" --no-stream
    else
        sudo docker stats --no-stream
    fi
}

backup_volumes() {
    print_header "Backup Container Volumes"
    BACKUP_DIR="$HOME/docker-backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    print_status "Backing up volumes to: $BACKUP_DIR"
    
    # Get all volumes
    VOLUMES=$(sudo docker volume ls -q)
    
    for volume in $VOLUMES; do
        print_status "Backing up volume: $volume"
        sudo docker run --rm -v "$volume":/volume -v "$BACKUP_DIR":/backup alpine tar czf "/backup/$volume.tar.gz" -C /volume .
    done
    
    print_status "Volume backup completed"
}

update_images() {
    print_header "Update Container Images"
    
    if [ -n "$CONTAINER" ]; then
        # Get image name for specific container
        IMAGE=$(sudo docker inspect "$CONTAINER" --format='{{.Config.Image}}')
        print_status "Updating image: $IMAGE"
        sudo docker pull "$IMAGE"
        
        print_status "Recreating container: $CONTAINER"
        sudo docker stop "$CONTAINER"
        sudo docker rm "$CONTAINER"
        print_warning "Container removed. Please recreate it with the updated image."
    else
        print_status "Updating all images"
        # Get all unique images from running containers
        IMAGES=$(sudo docker ps --format "table {{.Image}}" | tail -n +2 | sort -u)
        
        for image in $IMAGES; do
            print_status "Updating image: $image"
            sudo docker pull "$image"
        done
        
        print_warning "Images updated. Consider restarting containers to use new images."
    fi
}

# Execute command
case $COMMAND in
    status)
        show_status
        ;;
    start)
        start_containers
        ;;
    stop)
        stop_containers
        ;;
    restart)
        restart_containers
        ;;
    logs)
        show_logs
        ;;
    cleanup)
        cleanup_docker
        ;;
    stats)
        show_stats
        ;;
    backup)
        backup_volumes
        ;;
    update)
        update_images
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
