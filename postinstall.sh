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

# Function to uninstall a package using DNF
uninstall_dnf_package() {
    if dnf list installed "$1" &>/dev/null; then
        echo "Uninstalling $1..."
        sudo dnf remove "$1" -y
    else
        echo "$1 is not installed."
    fi
}

# Function to uninstall a Flatpak package
uninstall_flatpak_package() {
    if flatpak list | grep -q "$1"; then
        echo "Uninstalling Flatpak package $1..."
        sudo flatpak uninstall -y "$1"
    else
        echo "Flatpak package $1 is not installed."
    fi
}

# Function to uninstall a Snap package
uninstall_snap_package() {
    if snap list | grep -q "$1"; then
        echo "Uninstalling Snap package $1..."
        sudo snap remove "$1" || true
    else
        echo "Snap package $1 is not installed."
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

    # Uninstall Flatpak packages
    uninstall_flatpak_package "com.spotify.Client"
    uninstall_flatpak_package "com.bitwarden.desktop"

    # Uninstall Snap packages
    uninstall_snap_package "surfshark"

    # Remove the cloned repositories and configuration files
    echo "Removing configuration and theme files..."
    rm -rf "$GIT_DIR/mybash" "$GIT_DIR/chromebook-linux-audio" "$THEMES_DIR" "$ICONS_DIR"

    echo "Uninstallation completed!"
    exit 0
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

# Create necessary directories
echo "Setting up directories..."
mkdir -p "$OVERLORD_DIR/partial" "$OVERLORD_DIR/torrents"

# Ensure GIT_DIR exists
echo "Ensuring Git directory exists at $GIT_DIR..."
mkdir -p "$GIT_DIR"

# Copy Configurations, Themes, Pictures, and Fonts
echo "Copying configuration files..."
cp -rv "$INSTALL_STUFF_REPO/.config" "$HOME_DIR/"
cp -rv "$INSTALL_STUFF_REPO/Pictures/" "$HOME_DIR/"
cp -rv "$INSTALL_STUFF_REPO/.fonts/" "$HOME_DIR/"
cp -rv "$INSTALL_STUFF_REPO/.local" "$HOME_DIR"
fc-cache -fv

# Install CLI Pride Flags
echo "Installing Node.js and CLI Pride Flags..."
install_dnf_package "nodejs"
sudo npm install -g cli-pride-flags

# Install Kitty Terminal
install_dnf_package "kitty"

# Install sassc and libsass
install_dnf_package "sassc"
install_dnf_package "libsass"

# Install Snapd
echo "Installing Snapd..."
install_dnf_package "snapd"
sudo ln -s /var/lib/snapd/snap /snap || true
sudo systemctl enable --now snapd.socket

# Install qBittorrent
install_dnf_package "qbittorrent"

# Install LibreOffice
install_dnf_package "libreoffice"

# Install GTK Murine engine
install_dnf_package "gtk-murrine-engine"

# Install Surfshark via Snap (Beta)
sudo snap refresh
sudo dnf distro-sync --refresh
install_snap_package "surfshark"

# Install Flatpak and add Flathub repository
echo "Installing Flatpak and adding Flathub repository..."
install_dnf_package "flatpak"
sudo flatpak remote-add --if-not-exists flathub "$FLATPAK_REMOTE"

# Install Spotify and Bitwarden via Flatpak
install_flatpak_package "com.spotify.Client"
install_flatpak_package "com.bitwarden.desktop"

# Install Ulauncher
echo "Checking if Ulauncher is installed..."
if ! command_exists ulauncher; then
    echo "Ulauncher not found. Installing..."
    install_dnf_package "ulauncher"
else
    echo "Ulauncher is already installed."
fi

# Install Pulsar Editor
echo "Installing Pulsar Editor..."
PULSAR_RPM_URL="https://download.pulsar-edit.dev/?os=linux&type=linux_rpm"
PULSAR_RPM_FILE="$DOWNLOADS_DIR/pulsar.rpm"
wget -O "$PULSAR_RPM_FILE" "$PULSAR_RPM_URL"
sudo rpm -i "$PULSAR_RPM_FILE" || sudo dnf install -y "$PULSAR_RPM_FILE"
rm -f "$PULSAR_RPM_FILE"

# Install GTK theme
echo "Installing GTK theme..."
GTK_THEME_REPO="https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git"
GTK_THEME_DIR="$GIT_DIR/Gruvbox-GTK-Theme"

git clone --depth=1 "$GTK_THEME_REPO" "$GTK_THEME_DIR"

# Install the theme with specific tweaks
cd
cd git
cd  Gruvbox-GTK-Theme
cd themes
sudo chmod +x install.sh
./install.sh --tweaks outline float -t green -l -c dark

# Set the desktop background
set_desktop_background

# Check and ensure XFCE panel is running
check_xfce_panel

# Install DockBarX for XFCE
install_dnf_package "xfce4-dockbarx-plugin"

# Install Starship
install_starship

# Install MyBash if the flag is set
if [ "$INSTALL_MYBASH" = true ]; then
    install_mybash
fi

# Install any other packages and settings based on flags
if [ "$CHROMEBOOK_AUDIO_SETUP" = true ]; then
    echo "Setting up Chromebook Linux audio..."

    # Clone the Chromebook Linux Audio repository
    CHROMEBOOK_AUDIO_REPO="https://github.com/WeirdTreeThing/chromebook-linux-audio"
    CHROMEBOOK_AUDIO_DIR="$GIT_DIR/chromebook-linux-audio"

    git clone --depth=1 "$CHROMEBOOK_AUDIO_REPO" "$CHROMEBOOK_AUDIO_DIR"

    # Change to the cloned directory
    cd "$CHROMEBOOK_AUDIO_DIR"

    # Run the setup.sh script if it exists
    if [ -f "setup.sh" ]; then
        echo "Running the Chromebook Linux audio setup script..."
        chmod +x setup.sh  # Ensure the script is executable
        sudo ./setup.sh
    else
        echo "Error: setup.sh script not found in the Chromebook Linux audio repository."
        exit 1
    fi

    echo "Chromebook audio setup completed."
fi

# Set desktop background
set_desktop_background

# Completion Notification
echo "All done, $(whoami)! Your Fedora Linux setup is complete. Yippee!"
