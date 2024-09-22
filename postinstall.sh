#!/bin/bash

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and
# Ensure that errors in pipelines are not masked
set -euo pipefail

# Variables
HOME_DIR="/home/leigh"
GIT_DIR="$HOME_DIR/git"
INSTALL_STUFF_REPO="$GIT_DIR/install-stuff"
DESKTOP_DIR="$HOME_DIR/Desktop"
OVERLORD_DIR="$DESKTOP_DIR/overlord"
DOWNLOADS_DIR="$HOME_DIR/Downloads"
THEMES_DIR="$HOME_DIR/.local/share/themes"
ICONS_DIR="$HOME_DIR/.local/share/icons"
FLATPAK_REMOTE="https://flathub.org/repo/flathub.flatpakrepo"

# Flags
CHROMebook_AUDIO_SETUP=false

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c    Setup Chromebook Linux Audio"
    echo "  -h    Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 -c    Install all standard packages and set up Chromebook audio"
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

# Function to install a Flatpak package if not already installed
install_flatpak_package() {
    if ! flatpak list | grep -q "$1"; then
        echo "Installing Flatpak package $1..."
        sudo flatpak install flathub "$1" -y
    else
        echo "Flatpak package $1 is already installed."
    fi
}

# Function to install a Snap package if not already installed
install_snap_package() {
    if ! snap list | grep -q "$1"; then
        echo "Installing Snap package $1..."
        sudo snap install "$1" --beta
    else
        echo "Snap package $1 is already installed."
    fi
}

# Parse command-line options
while getopts ":ch" opt; do
    case ${opt} in
        c )
            CHROMebook_AUDIO_SETUP=true
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

# Update system packages
echo "Updating system packages..."
sudo dnf distro-sync --refresh -y

# Create necessary directories
echo "Setting up directories..."
mkdir -p "$OVERLORD_DIR/partial" "$OVERLORD_DIR/torrents"

# Ensure GIT_DIR exists
echo "Ensuring Git directory exists at $GIT_DIR..."
mkdir -p "$GIT_DIR"

# Clone or update the install-stuff repository
if [ ! -d "$INSTALL_STUFF_REPO" ]; then
    echo "Cloning install-stuff repository..."
    git clone https://github.com/yourusername/install-stuff.git "$INSTALL_STUFF_REPO"
else
    echo "install-stuff repository already exists. Pulling latest changes..."
    cd "$INSTALL_STUFF_REPO"
    git pull
fi

# Copy Configurations, Icons, Pictures, and Fonts
echo "Copying configuration files..."
cp -rv "$INSTALL_STUFF_REPO/.config" "$HOME_DIR/"
cp -rv "$INSTALL_STUFF_REPO/.icons" "$HOME_DIR/"
cp -rv "$INSTALL_STUFF_REPO/Pictures/" "$HOME_DIR/"
cp -rv "$INSTALL_STUFF_REPO/.fonts/" "$HOME_DIR/"
fc-cache -fv

# Install CLI Pride Flags
echo "Installing Node.js and CLI Pride Flags..."
install_dnf_package "nodejs"
sudo npm install -g cli-pride-flags

# Install Kitty Terminal
install_dnf_package "kitty"

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

# Install Gruvbox Plus Icon Pack
echo "Installing Gruvbox Plus Icon Pack..."
GRUVBOX_ICONS_REPO="https://github.com/SylEleuth/gruvbox-plus-icon-pack.git"
GRUVBOX_ICONS_DIR="$GIT_DIR/gruvbox-plus-icon-pack"

if [ ! -d "$GRUVBOX_ICONS_DIR" ]; then
    git clone "$GRUVBOX_ICONS_REPO" "$GRUVBOX_ICONS_DIR"
else
    echo "Gruvbox Plus Icon Pack repository already exists. Pulling latest changes..."
    cd "$GRUVBOX_ICONS_DIR"
    git pull
fi

cp -rv "$GRUVBOX_ICONS_DIR/Gruvbox-Plus-Dark" "$ICONS_DIR"

# Install GTK Theme
echo "Installing GTK theme..."
GTK_THEME_REPO="https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git"
GTK_THEME_DIR="$GIT_DIR/Gruvbox-GTK-Theme"

if [ ! -d "$GTK_THEME_DIR" ]; then
    git clone "$GTK_THEME_REPO" "$GTK_THEME_DIR"
else
    echo "Gruvbox GTK Theme repository already exists. Pulling latest changes..."
    cd "$GTK_THEME_DIR"
    git pull
fi

cd "$GTK_THEME_DIR/themes"
sudo ./install.sh -l -t green -c dark --tweaks float outline

# Override Flatpak permissions for themes and icons
echo "Overriding Flatpak permissions for themes and icons..."
sudo flatpak override --filesystem="$THEMES_DIR"
sudo flatpak override --filesystem="$ICONS_DIR"
flatpak override --user --filesystem="$HOME_DIR/.config/gtk-4.0"
sudo flatpak override --filesystem="$HOME_DIR/.config/gtk-4.0"

# Install Chris Titus Script
echo "Installing Chris Titus Tech setup script..."
CHRIS_TITUS_REPO="https://github.com/ChrisTitusTech/mybash.git"
CHRIS_TITUS_DIR="$GIT_DIR/mybash"

if [ ! -d "$CHRIS_TITUS_DIR" ]; then
    git clone --depth=1 "$CHRIS_TITUS_REPO" "$CHRIS_TITUS_DIR"
else
    echo "Chris Titus Tech repository already exists. Pulling latest changes..."
    cd "$CHRIS_TITUS_DIR"
    git pull
fi

cd "$CHRIS_TITUS_DIR"
chmod +x setup.sh
./setup.sh
cd "$HOME_DIR"

# Chromebook Audio Setup (Flag: -c)
if [ "$CHROMebook_AUDIO_SETUP" = true ]; then
    echo "Setting up Chromebook Linux Audio..."
    CHROMebook_AUDIO_REPO="https://github.com/WeirdTreeThing/chromebook-linux-audio.git"
    CHROMebook_AUDIO_DIR="$GIT_DIR/chromebook-linux-audio"

    if [ ! -d "$CHROMebook_AUDIO_DIR" ]; then
        echo "Cloning Chromebook Linux Audio repository..."
        git clone "$CHROMebook_AUDIO_REPO" "$CHROMebook_AUDIO_DIR"
    else
        echo "Chromebook Linux Audio repository already exists. Pulling latest changes..."
        cd "$CHROMebook_AUDIO_DIR"
        git pull
    fi

    echo "Running setup-audio script..."
    cd "$CHROMebook_AUDIO_DIR"
    chmod +x setup-audio
    ./setup-audio
    cd "$HOME_DIR"
fi

# Completion Notification
echo "All done, Leigh! Your system setup is complete."
