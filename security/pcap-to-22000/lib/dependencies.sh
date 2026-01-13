#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/dependencies.sh
#
#   Dependency checking and installation functions
# ----------------------------------------------------------------------

# Check if a command exists in PATH
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect the package manager available on the system
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    elif command_exists brew; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Install hcxtools using the detected package manager
install_hcxtools() {
    local PM="$1"
    local INSTALL_CMD=""
    local PKG_NAME=""

    case "$PM" in
        apt)
            INSTALL_CMD="sudo apt-get update && sudo apt-get install -y hcxtools"
            PKG_NAME="hcxtools"
            ;;
        yum)
            INSTALL_CMD="sudo yum install -y hcxtools"
            PKG_NAME="hcxtools"
            ;;
        dnf)
            INSTALL_CMD="sudo dnf install -y hcxtools"
            PKG_NAME="hcxtools"
            ;;
        pacman)
            INSTALL_CMD="sudo pacman -S --noconfirm hcxtools"
            PKG_NAME="hcxtools"
            ;;
        zypper)
            INSTALL_CMD="sudo zypper install -y hcxtools"
            PKG_NAME="hcxtools"
            ;;
        brew)
            INSTALL_CMD="brew install hcxtools"
            PKG_NAME="hcxtools"
            ;;
        *)
            return 1
            ;;
    esac

    echo "Installing $PKG_NAME using $PM..."
    echo "Running: $INSTALL_CMD"
    
    if eval "$INSTALL_CMD"; then
        echo "✅ Successfully installed $PKG_NAME"
        return 0
    else
        echo "❌ Failed to install $PKG_NAME" >&2
        return 1
    fi
}

# Check if hcxpcapngtool is available, install if missing
check_dependencies() {
    local AUTO_INSTALL="${1:-1}"  # Default to auto-install enabled
    local MISSING_DEPS=()

    # Check for hcxpcapngtool
    if ! command_exists hcxpcapngtool; then
        MISSING_DEPS+=("hcxtools (hcxpcapngtool)")
    fi

    # If no missing dependencies, return success
    if (( ${#MISSING_DEPS[@]} == 0 )); then
        return 0
    fi

    # Report missing dependencies
    echo "Missing dependencies detected:" >&2
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep" >&2
    done
    echo >&2

    # Attempt auto-install if enabled
    if (( AUTO_INSTALL == 1 )); then
        local PM
        PM=$(detect_package_manager)
        
        if [[ "$PM" == "unknown" ]]; then
            echo "⚠️  Could not detect package manager. Please install dependencies manually:" >&2
            for dep in "${MISSING_DEPS[@]}"; do
                echo "  - $dep" >&2
            done
            echo >&2
            echo "Visit https://github.com/ZerBea/hcxtools for installation instructions." >&2
            return 1
        fi

        # Try to install hcxtools
        if [[ " ${MISSING_DEPS[*]} " =~ hcxtools ]]; then
            if ! install_hcxtools "$PM"; then
                echo "⚠️  Auto-installation failed. Please install hcxtools manually:" >&2
                echo "  Visit https://github.com/ZerBea/hcxtools for installation instructions." >&2
                return 1
            fi
        fi

        # Verify installation succeeded
        if ! command_exists hcxpcapngtool; then
            echo "⚠️  Installation completed but hcxpcapngtool is still not found in PATH." >&2
            echo "   You may need to restart your terminal or update your PATH." >&2
            return 1
        fi

        return 0
    else
        # Auto-install disabled, just report
        echo "Please install the missing dependencies manually:" >&2
        for dep in "${MISSING_DEPS[@]}"; do
            echo "  - $dep" >&2
        done
        echo >&2
        echo "Visit https://github.com/ZerBea/hcxtools for installation instructions." >&2
        return 1
    fi
}
