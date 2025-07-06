#!/bin/bash
# network-monitor.sh - Monitor network status and Tailscale connectivity
# Usage: ./network-monitor.sh [--continuous] [--interface INTERFACE]

set -e

# Default configuration
CONTINUOUS=false
INTERFACE=""
CHECK_INTERVAL=5

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--continuous)
            CONTINUOUS=true
            shift
            ;;
        -i|--interface)
            INTERFACE="$2"
            shift 2
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--continuous] [--interface INTERFACE] [--interval SECONDS]"
            echo "  --continuous    Monitor continuously"
            echo "  --interface     Specify network interface to monitor"
            echo "  --interval      Check interval for continuous mode (default: 5)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[NETWORK]${NC} $1"
}

# Function to check internet connectivity
check_internet() {
    local test_sites=("8.8.8.8" "1.1.1.1" "google.com")
    local connected=false
    
    for site in "${test_sites[@]}"; do
        if ping -c 1 -W 3 "$site" &> /dev/null; then
            connected=true
            break
        fi
    done
    
    if [ "$connected" = true ]; then
        print_status "Internet connectivity: ✓ Connected"
        return 0
    else
        print_error "Internet connectivity: ✗ Disconnected"
        return 1
    fi
}

# Function to check Tailscale status
check_tailscale() {
    if command -v tailscale &> /dev/null; then
        local status=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")
        local ip=$(tailscale ip -4 2>/dev/null || echo "none")
        
        case $status in
            "Running")
                print_status "Tailscale: ✓ Running (IP: $ip)"
                
                # Test connectivity to other Tailscale nodes
                print_header "Testing Tailscale node connectivity:"
                local nodes=("aurumos" "eresos" "saeulfr" "pi4-router" "brokkr")
                for node in "${nodes[@]}"; do
                    if [ "$node" != "$(hostname)" ]; then
                        if ping -c 1 -W 2 "$node" &> /dev/null; then
                            echo "  $node: ✓"
                        else
                            echo "  $node: ✗"
                        fi
                    fi
                done
                ;;
            "Stopped"|"NeedsLogin")
                print_warning "Tailscale: ⚠ $status"
                ;;
            *)
                print_error "Tailscale: ✗ $status"
                ;;
        esac
    else
        print_warning "Tailscale not installed"
    fi
}

# Function to show network interfaces
show_interfaces() {
    print_header "Network Interfaces:"
    if [ -n "$INTERFACE" ]; then
        ip addr show "$INTERFACE" 2>/dev/null || print_error "Interface $INTERFACE not found"
    else
        ip -br addr show | while read line; do
            interface=$(echo $line | awk '{print $1}')
            state=$(echo $line | awk '{print $2}')
            ip_addr=$(echo $line | awk '{print $3}')
            
            case $state in
                "UP")
                    echo "  $interface: ✓ $state ($ip_addr)"
                    ;;
                "DOWN")
                    echo "  $interface: ✗ $state"
                    ;;
                *)
                    echo "  $interface: ? $state ($ip_addr)"
                    ;;
            esac
        done
    fi
}

# Function to show routing information
show_routes() {
    print_header "Default Routes:"
    ip route show default | while read line; do
        echo "  $line"
    done
    
    if command -v tailscale &> /dev/null; then
        print_header "Tailscale Routes:"
        ip route show | grep "100.64" 2>/dev/null | while read line; do
            echo "  $line"
        done || echo "  No Tailscale routes found"
    fi
}

# Function to show DNS information
show_dns() {
    print_header "DNS Configuration:"
    if [ -f /etc/resolv.conf ]; then
        grep -E "^nameserver|^search" /etc/resolv.conf | while read line; do
            echo "  $line"
        done
    fi
    
    # Test DNS resolution
    print_header "DNS Resolution Test:"
    local test_domains=("google.com" "github.com")
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" &> /dev/null; then
            echo "  $domain: ✓"
        else
            echo "  $domain: ✗"
        fi
    done
}

# Function to show network statistics
show_stats() {
    print_header "Network Statistics:"
    if [ -n "$INTERFACE" ]; then
        cat "/sys/class/net/$INTERFACE/statistics/rx_bytes" 2>/dev/null | \
            awk '{printf "  %s RX: %.2f MB\n", "'$INTERFACE'", $1/1024/1024}' || \
            print_error "Cannot read stats for $INTERFACE"
        cat "/sys/class/net/$INTERFACE/statistics/tx_bytes" 2>/dev/null | \
            awk '{printf "  %s TX: %.2f MB\n", "'$INTERFACE'", $1/1024/1024}' || \
            print_error "Cannot read stats for $INTERFACE"
    else
        for iface in /sys/class/net/*/statistics; do
            interface=$(basename $(dirname $iface))
            [ "$interface" = "lo" ] && continue
            
            rx_bytes=$(cat "$iface/rx_bytes" 2>/dev/null || echo 0)
            tx_bytes=$(cat "$iface/tx_bytes" 2>/dev/null || echo 0)
            
            printf "  %s RX: %.2f MB, TX: %.2f MB\n" \
                "$interface" \
                "$((rx_bytes/1024/1024))" \
                "$((tx_bytes/1024/1024))"
        done
    fi
}

# Function to show port scan for common services
show_ports() {
    print_header "Common Service Ports:"
    local ports=(22 80 443 3000 5432 6379 8080 9000)
    for port in "${ports[@]}"; do
        if ss -tuln | grep ":$port " &> /dev/null; then
            echo "  Port $port: ✓ Open"
        else
            echo "  Port $port: ✗ Closed"
        fi
    done
}

# Main monitoring function
monitor_network() {
    clear
    echo "================================================"
    echo "          Network Monitor - $(date)"
    echo "================================================"
    echo
    
    check_internet
    echo
    
    check_tailscale
    echo
    
    show_interfaces
    echo
    
    show_routes
    echo
    
    show_dns
    echo
    
    show_stats
    echo
    
    show_ports
    echo
    
    echo "================================================"
}

# Main execution
if [ "$CONTINUOUS" = true ]; then
    print_status "Starting continuous network monitoring (interval: ${CHECK_INTERVAL}s)"
    print_status "Press Ctrl+C to stop"
    
    while true; do
        monitor_network
        sleep "$CHECK_INTERVAL"
    done
else
    monitor_network
fi
