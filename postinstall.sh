#!/bin/bash

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and
# Ensure that errors in pipelines are not masked
set -euo pipefail

# Variables
HOME_DIR="/home/$USER"
GIT_DIR="$HOME_DIR/git"
INSTALL_STUFF_REPO="$GIT_DIR/install-stuff"
DESKTOP_DIR="$HOME_DIR/Desktop"
OVERLORD_DIR="$DESKTOP_DIR/overlord"
DOWNLOADS_DIR="$HOME_DIR/Downloads"
THEMES_DIR="$HOME_DIR/.local/share/themes"
ICONS_DIR="$HOME_DIR/.local/share/icons"
FLATPAK_REMOTE="https://flathub.org/repo/flathub.flatpakrepo"
BACKGROUND_IMAGE="$HOME_DIR/Pictures/gruvbox/gruvbox_random.png"

# Flags
CHROMEBOOK_AUDIO_SETUP=false
DESKTOP_ENVIRONMENT=""
INSTALL_MYBASH=false
UNINSTALL=false

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c    Setup Chromebook Linux Audio"
    echo "  -d [kde|gnome|xfce]    Specify desktop environment (default is auto-detected)"
    echo "  -t    Install MyBash from Chris Titus Tech"
    echo "  -u    Uninstall all installed packages and settings"
    echo "  -h    Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 -c -d xfce    Install all standard packages and set up Chromebook audio on XFCE"
    echo "  $0 -t           Install MyBash"
    echo "  $0 -u           Uninstall everything"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package using DNF if not already installed
install_dnf_package() {
    if ! dnf list installed "$1" &>/dev/null; then
        echo "Installing $1..."
        sudo dnf install "$1" -y
    else
        echo "$1 is already installed."
    fi
}

# Function to uninstall a package using DNF
uninstall_dnf_package() {
    if dnf list installed "$1" &>/dev/null; then
        echo "Uninstalling $1..."
        sudo dnf remove "$1" -y
    else
        echo "$1 is not installed."
    fi
}

# Function to perform uninstallation
perform_uninstall() {
    echo "Starting uninstallation process..."

    # Uninstall packages
    uninstall_dnf_package "nodejs"
    uninstall_dnf_package "kitty"
    uninstall_dnf_package "sassc"
    uninstall_dnf_package "libsass"
    uninstall_dnf_package "snapd"
    uninstall_dnf_package "qbittorrent"
    uninstall_dnf_package "libreoffice"
    uninstall_dnf_package "gtk-murrine-engine"
    uninstall_dnf_package "xfce4-dockbarx-plugin"
    uninstall_dnf_package "ulauncher"
    uninstall_dnf_package "xfce4-docklike-plugin"  # Remove xfce4-docklike-plugin

    # Remove the cloned repositories and configuration files
    echo "Removing configuration and theme files..."
    rm -rf "$GIT_DIR/mybash" "$GIT_DIR/chromebook-linux-audio" "$THEMES_DIR" "$ICONS_DIR"

    echo "Uninstallation completed!"
    exit 0
}

# Function to detect the desktop environment
detect_desktop_environment() {
    if command_exists kwin_wayland; then
        DESKTOP_ENVIRONMENT="kde"
    elif command_exists gnome-shell; then
        DESKTOP_ENVIRONMENT="gnome"
    elif command_exists xfce4-session; then
        DESKTOP_ENVIRONMENT="xfce"
    else
        echo "Unable to detect desktop environment. Please specify with the -d option."
        usage
    fi
}

# Function to install the Docklike plugin from source
install_docklike_plugin() {
    echo "Installing xfce4-docklike-plugin from source..."

    # Install dependencies
    install_dnf_package "xfce4-dev-tools"
    install_dnf_package "cmake"

    # Clone the repository
    git clone https://github.com/nsz32/docklike-plugin "$GIT_DIR/docklike-plugin"
    cd "$GIT_DIR/docklike-plugin"

    # Build and install
    ./autogen.sh
    make
    sudo make install

    echo "xfce4-docklike-plugin installed successfully."
}

# Function to set the desktop background
set_desktop_background() {
    case "$DESKTOP_ENVIRONMENT" in
        kde)
            kwriteconfig5 --file "$(kreadconfig5 --file kiwin --key SystemSettings)" --group "Wallpaper" --key "Image" "$BACKGROUND_IMAGE"
            ;;
        gnome)
            gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_IMAGE"
            ;;
        xfce)
            xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$BACKGROUND_IMAGE"
            ;;
    esac
}

# Function to install Starship
install_starship() {
    if ! command_exists starship; then
        echo "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh
        echo 'eval "$(starship init bash)"' >> "$HOME_DIR/.bashrc"
        echo "Starship installed successfully."
    else
        echo "Starship is already installed."
    fi
}

# Function to install MyBash
install_mybash() {
    echo "Installing MyBash from Chris Titus Tech..."
    git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git "$GIT_DIR/mybash"
    cd "$GIT_DIR/mybash"
    chmod +x setup.sh
    ./setup.sh
    echo "MyBash installation completed."
}

# Function to install CLI Pride Flags
install_cli_pride_flags() {
    echo "Installing Node.js and CLI Pride Flags..."
    install_dnf_package "nodejs"
    sudo npm install -g cli-pride-flags
}

# Parse command-line options
while getopts ":cd:thu" opt; do
    case ${opt} in
        c )
            CHROMEBOOK_AUDIO_SETUP=true
            ;;
        d )
            DESKTOP_ENVIRONMENT="$OPTARG"
            ;;
        t )
            INSTALL_MYBASH=true
            ;;
        u )
            UNINSTALL=true
            ;;
        h )
            usage
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# If uninstall flag is set, perform uninstallation
if [ "$UNINSTALL" = true ]; then
    perform_uninstall
fi

# Detect desktop environment if not specified
if [ -z "$DESKTOP_ENVIRONMENT" ]; then
    detect_desktop_environment
fi

# Update system packages
echo "Updating system packages..."
sudo dnf distro-sync --refresh -y

# Ensure GIT_DIR exists
echo "Ensuring Git directory exists at $GIT_DIR..."
mkdir -p "$GIT_DIR"

# Install essential applications
install_dnf_package "kitty"
install_dnf_package "sassc"
install_dnf_package "libsass"
install_dnf_package "snapd"
install_dnf_package "qbittorrent"
install_dnf_package "libreoffice"
install_dnf_package "gtk-murrine-engine"
install_dnf_package "ulauncher"

# Install the Docklike plugin
install_docklike_plugin

# Set the desktop background
set_desktop_background

# Install Starship
install_starship

# Install MyBash if flag is set
if [ "$INSTALL_MYBASH" = true ]; then
    install_mybash
fi

# Install CLI Pride Flags
install_cli_pride_flags

# Check for Chromebook Audio Setup
if [ "$CHROMEBOOK_AUDIO_SETUP" = true ]; then
    echo "Setting up Chromebook Linux Audio..."
    git clone --depth=1 https://github.com/ChrisTitusTech/chromebook-linux-audio.git "$GIT_DIR/chromebook-linux-audio"
    cd "$GIT_DIR/chromebook-linux-audio"
    chmod +x setup.sh
    ./setup.sh
fi

# Completion Notification
echo "All done, $(whoami)! Your Fedora Linux setup is complete. Yippee!"
