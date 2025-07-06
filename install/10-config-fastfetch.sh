#!/bin/bash

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
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Use AUR_HELPER environment variable, fallback to yay
AUR_HELPER=${AUR_HELPER:-yay}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"

# Function to backup existing files
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_file="${file}.backup-$(date +%Y%m%d_%H%M%S)"
        print_status "Backing up existing $file to $backup_file"
        cp "$file" "$backup_file" || {
            print_error "Failed to backup $file"
            return 1
        }
    fi
}

# Function to install Fastfetch
install_fastfetch() {
    print_status "Checking if Fastfetch is installed..."
    
    if ! command -v fastfetch &> /dev/null; then
        if gum confirm "Fastfetch not found. Install Fastfetch using $AUR_HELPER?"; then
            print_status "Installing Fastfetch..."
            
            # Try to install from official repositories first
            if sudo pacman -S --needed --noconfirm fastfetch; then
                print_status "Fastfetch installed successfully from official repositories"
            else
                print_warning "Failed to install from official repositories, trying with $AUR_HELPER..."
                if "$AUR_HELPER" -S --needed --noconfirm fastfetch; then
                    print_status "Fastfetch installed successfully using $AUR_HELPER"
                else
                    print_error "Failed to install Fastfetch"
                    return 1
                fi
            fi
        else
            print_error "Fastfetch is required for this configuration"
            return 1
        fi
    else
        print_status "Fastfetch is already installed"
        fastfetch --version
    fi
}

# Function to create fastfetch config directory
create_fastfetch_config_dir() {
    local fastfetch_dir="$HOME/.config/fastfetch"
    
    if [[ ! -d "$fastfetch_dir" ]]; then
        print_status "Creating Fastfetch configuration directory..."
        mkdir -p "$fastfetch_dir" || {
            print_error "Failed to create Fastfetch configuration directory"
            return 1
        }
        print_status "Fastfetch configuration directory created at $fastfetch_dir"
    else
        print_status "Fastfetch configuration directory already exists"
    fi
}

# Function to create a default fastfetch configuration
create_fastfetch_config() {
    print_status "Creating Fastfetch configuration..."
    
    local fastfetch_dir="$HOME/.config/fastfetch"
    local config_file="$fastfetch_dir/config.jsonc"
    
    # Create config directory
    create_fastfetch_config_dir || return 1
    
    if gum confirm "Create a custom Fastfetch configuration?"; then
        # Backup existing config
        backup_file "$config_file"
        
        # Create new config file
        cat > "$config_file" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch",
        "padding": {
            "top": 1,
            "left": 2
        }
    },
    "display": {
        "separator": " -> ",
        "color": {
            "keys": "blue",
            "title": "blue"
        }
    },
    "modules": [
        {
            "type": "title",
            "color": {
                "user": "blue",
                "at": "white",
                "host": "green"
            }
        },
        "separator",
        {
            "type": "os",
            "key": " OS"
        },
        {
            "type": "kernel",
            "key": "│ ├  Kernel"
        },
        {
            "type": "packages",
            "key": "│ ├  Packages"
        },
        {
            "type": "shell",
            "key": "│ └  Shell"
        },
        "break",
        {
            "type": "wm",
            "key": " DE/WM"
        },
        {
            "type": "theme",
            "key": "│ ├  Theme"
        },
        {
            "type": "icons",
            "key": "│ ├  Icons"
        },
        {
            "type": "terminal",
            "key": "│ └  Terminal"
        },
        "break",
        {
            "type": "host",
            "key": " PC"
        },
        {
            "type": "cpu",
            "key": "│ ├  CPU"
        },
        {
            "type": "gpu",
            "key": "│ ├  GPU"
        },
        {
            "type": "memory",
            "key": "│ ├  Memory"
        },
        {
            "type": "uptime",
            "key": "│ ├  Uptime"
        },
        {
            "type": "display",
            "key": "│ └  Resolution"
        },
        "break",
        {
            "type": "disk",
            "key": "│  Disk (/)",
            "folders": "/"
        },
        {
            "type": "disk",
            "key": "│  Disk (Data)",
            "folders": "/run/media/$USER/Data"
        },
        "separator",
        {
            "type": "colors",
            "paddingLeft": 2,
            "symbol": "circle"
        }
    ]
}
EOF
        
        if [[ $? -eq 0 ]]; then
            print_status "Fastfetch configuration created successfully"
            
            # Update the hostname in the disk path
            local current_user=$(whoami)
            sed -i "s/\$USER/$current_user/g" "$config_file"
            print_status "Configuration updated for user: $current_user"
        else
            print_error "Failed to create Fastfetch configuration"
            return 1
        fi
    else
        print_warning "Skipping Fastfetch configuration creation"
    fi
}

# Function to copy existing fastfetch configuration if available
copy_fastfetch_config() {
    print_status "Checking for existing Fastfetch configuration..."
    
    local source_config="$CONFIG_DIR/fastfetch/config.jsonc"
    local target_config="$HOME/.config/fastfetch/config.jsonc"
    
    if [[ -f "$source_config" ]]; then
        if gum confirm "Copy existing Fastfetch configuration file?"; then
            # Create config directory if it doesn't exist
            create_fastfetch_config_dir || return 1
            
            # Backup existing config
            backup_file "$target_config"
            
            # Copy new config
            cp "$source_config" "$target_config" || {
                print_error "Failed to copy Fastfetch configuration"
                return 1
            }
            print_status "Fastfetch configuration copied successfully"
        else
            print_warning "Skipping existing Fastfetch configuration copy"
            # Create a new one instead
            create_fastfetch_config
        fi
    else
        print_status "No existing Fastfetch configuration found, creating new one..."
        create_fastfetch_config
    fi
}

# Function to test fastfetch installation
test_fastfetch() {
    print_status "Testing Fastfetch installation..."
    
    if gum confirm "Run a test of Fastfetch to verify it's working?"; then
        print_status "Running Fastfetch test..."
        echo
        fastfetch || {
            print_error "Fastfetch test failed"
            return 1
        }
        echo
        print_status "Fastfetch test completed successfully"
    else
        print_warning "Skipping Fastfetch test"
    fi
}

# Function to add fastfetch to shell startup (optional)
add_fastfetch_to_shell() {
    print_status "Checking shell startup configuration..."
    
    if gum confirm "Add Fastfetch to your shell startup (.zshrc or .bashrc)?"; then
        local shell_config=""
        
        # Determine which shell config to use
        if [[ -f "$HOME/.zshrc" ]]; then
            shell_config="$HOME/.zshrc"
        elif [[ -f "$HOME/.bashrc" ]]; then
            shell_config="$HOME/.bashrc"
        else
            print_warning "No shell configuration file found (.zshrc or .bashrc)"
            return 1
        fi
        
        # Check if fastfetch is already in the config
        if grep -q "fastfetch" "$shell_config"; then
            print_status "Fastfetch is already configured in $shell_config"
        else
            print_status "Adding Fastfetch to $shell_config..."
            echo "" >> "$shell_config"
            echo "# Display system information with Fastfetch" >> "$shell_config"
            echo "fastfetch" >> "$shell_config"
            print_status "Fastfetch added to $shell_config"
            print_warning "Restart your terminal or run 'source $shell_config' to see the changes"
        fi
    else
        print_warning "Skipping shell startup configuration"
    fi
}

# Function to install additional dependencies
install_dependencies() {
    print_status "Checking for additional dependencies..."
    
    # Check for imagemagick (for image support)
    if ! command -v convert &> /dev/null; then
        if gum confirm "ImageMagick not found. Install it for image support in Fastfetch?"; then
            print_status "Installing ImageMagick..."
            sudo pacman -S --needed --noconfirm imagemagick || {
                print_warning "Failed to install ImageMagick"
            }
        fi
    else
        print_status "ImageMagick is already installed"
    fi
    
    # Check for chafa (for better image support)
    if ! command -v chafa &> /dev/null; then
        if gum confirm "Chafa not found. Install it for better image support in Fastfetch?"; then
            print_status "Installing Chafa..."
            sudo pacman -S --needed --noconfirm chafa || {
                print_warning "Failed to install Chafa"
            }
        fi
    else
        print_status "Chafa is already installed"
    fi
}

# Function to create fastfetch config directory in project
create_project_config_dir() {
    local project_fastfetch_dir="$CONFIG_DIR/fastfetch"
    
    if [[ ! -d "$project_fastfetch_dir" ]]; then
        print_status "Creating project Fastfetch configuration directory..."
        mkdir -p "$project_fastfetch_dir" || {
            print_warning "Failed to create project Fastfetch configuration directory"
            return 1
        }
        print_status "Project Fastfetch configuration directory created"
    fi
}

# Main installation process
print_section "=== Fastfetch Configuration Setup ==="
echo

# Check if gum is available
if ! command -v gum &> /dev/null; then
    print_error "gum is required but not installed. Please install gum first."
    exit 1
fi

# Install Fastfetch
if ! install_fastfetch; then
    print_error "Failed to install Fastfetch"
    exit 1
fi

# Install additional dependencies
install_dependencies

# Create project config directory
create_project_config_dir

# Copy or create fastfetch configuration
if ! copy_fastfetch_config; then
    print_error "Failed to setup Fastfetch configuration"
    exit 1
fi

# Test fastfetch installation
test_fastfetch

# Add fastfetch to shell startup (optional)
add_fastfetch_to_shell

print_section "Fastfetch configuration setup completed successfully!"
print_status "Your system information tool is now configured with:"
print_status "  - Fastfetch system information display"
print_status "  - Custom JSON configuration file with styled output"
print_status "  - Optional shell startup integration"
print_status "  - Optional image support dependencies"
echo
print_status "You can run 'fastfetch' at any time to display system information"
print_status "Configuration file: ~/.config/fastfetch/config.jsonc"
print_warning "If you added Fastfetch to your shell startup, restart your terminal to see it automatically"
