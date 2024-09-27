#!/bin/bash

set -euo pipefail

# Variables
SUDO_USER=${SUDO_USER:-$(whoami)}
HOME_DIR="/home/$SUDO_USER"
GIT_DIR="$HOME_DIR/git"
INSTALL_STUFF_REPO="$GIT_DIR/install-stuff"
DESKTOP_DIR="$HOME_DIR/Desktop"
OVERLORD_DIR="$DESKTOP_DIR/overlord"
DOWNLOADS_DIR="$HOME_DIR/Downloads"
THEMES_DIR="$HOME_DIR/.local/share/themes"
ICONS_DIR="$HOME_DIR/.local/share/icons"
BACKGROUND_IMAGE="$HOME_DIR/Pictures/gruvbox/gruvbox_random.png"
LOG_FILE="/tmp/fedora_setup_$(date +%Y%m%d_%H%M%S).log"
DOCKLIKE_RPM="$INSTALL_STUFF_REPO/rpms/xfce4-docklike-plugin-0.4.2-1.fc40.x86_64.rpm"

# Flags
INSTALL_CHROMEBOOK_AUDIO=false

# Parse command-line options
while getopts ":c" opt; do
  case ${opt} in
    c )
      INSTALL_CHROMEBOOK_AUDIO=true
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
  esac
done

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo" 1>&2
    exit 1
fi

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ... [Other functions remain the same] ...

# Function to install Chromebook audio setup
install_chromebook_audio() {
    log_message "Setting up Chromebook Linux audio..."
    if ! git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git "$GIT_DIR/chromebook-linux-audio"; then
        log_message "Error: Failed to clone chromebook-linux-audio repository"
    else
        pushd "$GIT_DIR/chromebook-linux-audio" || exit 1
        chmod +x setup-audio
        ./setup-audio || log_message "Warning: Failed to run setup-audio script"
        popd || exit 1
    fi
}

# Main execution starts here
log_message "Starting Fedora setup script for XFCE"

# Update the system
update_system

# Create necessary directories
create_directories

# Backup existing configurations
backup_configs

# Copy configuration files
log_message "Copying configuration files..."
cp -rv "$INSTALL_STUFF_REPO/.config" "$HOME_DIR/" || log_message "Warning: Failed to copy .config"
cp -rv "$INSTALL_STUFF_REPO/.fonts" "$HOME_DIR/" || log_message "Warning: Failed to copy .fonts"
cp -rv "$INSTALL_STUFF_REPO/.icons" "$HOME_DIR/" || log_message "Warning: Failed to copy .icons"

# Install apps
log_message "Installing applications..."
apps=(
    "sassc" "libsass" "nodejs" "kitty" "snapd" "qbittorrent" "libreoffice"
    "gtk-murrine-engine" "ulauncher" "cmake" "libtool" "xfce4-docklike-plugin"
    "clapper" "git" "curl" "wget" "vim" "nano" "htop"
)
for app in "${apps[@]}"; do
    install_dnf_package "$app"
done

# Install starship
install_dnf_package "starship"

# Install Bash Autocomplete
install_dnf_package "bash-completion"

# Install Flatpak applications
log_message "Installing Flatpak applications..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y bitwarden spotify || log_message "Warning: Failed to install Flatpak applications"

# Set up Snap
log_message "Setting up Snap..."
systemctl enable --now snapd.socket || log_message "Warning: Failed to enable snapd.socket"
ln -sf /var/lib/snapd/snap /snap || log_message "Warning: Failed to create snap symlink"
snap refresh || log_message "Warning: Failed to refresh snap"
snap install surfshark --edge || log_message "Warning: Failed to install Surfshark"

# Install Chromebook audio setup if flag is set
if [ "$INSTALL_CHROMEBOOK_AUDIO" = true ]; then
    install_chromebook_audio
else
    log_message "Skipping Chromebook audio setup (use -c flag to enable)"
fi

install_dnf_package "chromium"
uninstall_dnf_package "firefox"

# Install MyBash from Chris Titus Tech
install_dnf_package "fastfetch"
install_mybash

# Install CLI Pride Flags
log_message "Installing CLI Pride Flags..."
if command_exists npm; then
    npm i -g cli-pride-flags || log_message "Warning: Failed to install CLI Pride Flags"
else
    log_message "Warning: npm not found. Skipping CLI Pride Flags installation."
fi

# Set desktop background
set_desktop_background

# Install Pulsar
log_message "Installing Pulsar..."
pushd "$INSTALL_STUFF_REPO/rpms" || exit 1
if ! curl -L -o pulsar.rpm "https://download.pulsar-edit.dev/?os=linux&type=linux_rpm"; then
    log_message "Error: Failed to download Pulsar RPM"
else
    rpm -i pulsar.rpm || log_message "Warning: Failed to install Pulsar RPM"
fi
popd || exit 1

# Install icons
log_message "Installing Gruvbox Plus icons..."
pushd "$GIT_DIR/install-stuff" || exit 1
if ! curl -L -o gruvbox-plus-icons.zip https://github.com/SylEleuth/gruvbox-plus-icon-pack/releases/download/v5.5.0/gruvbox-plus-icon-pack-5.5.0.zip; then
    log_message "Error: Failed to download Gruvbox Plus icons"
else
    unzip -o gruvbox-plus-icons.zip -d "$HOME_DIR/.local/share/icons/" || log_message "Warning: Failed to extract icons to .local/share/icons"
    unzip -o gruvbox-plus-icons.zip -d "$HOME_DIR/.icons/" || log_message "Warning: Failed to extract icons to .icons"
fi
popd || exit 1

# Install xfce dock like plugin if applicable
install_xfce_docklike_plugin

# Install GTK themes
log_message "Installing GTK themes..."
cd "$GIT_DIR" || exit 1
if ! git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git; then
    log_message "Error: Failed to clone Gruvbox-GTK-Theme repository"
else
    cd Gruvbox-GTK-Theme/themes || exit 1
    ./install.sh --tweaks outline float -t green -l -c dark || log_message "Warning: Failed to install GTK themes"
fi
cd || exit 1

# Flatpak overrides for themes and icons
flatpak override --user --filesystem=$HOME/.themes || log_message "Warning: Failed to set Flatpak override for .themes"
flatpak override --user --filesystem=$HOME/.icons || log_message "Warning: Failed to set Flatpak override for .icons"
flatpak override --user --filesystem=xdg-config/gtk-4.0 || log_message "Warning: Failed to set Flatpak override for gtk-4.0"

# Set correct permissions for the home directory
chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR"

# Completion Notification
log_message "All done, $SUDO_USER! Your Fedora Linux setup for XFCE is complete. Yippee!"
log_message "Setup completed. Log file: $LOG_FILE"

# Prompt for reboot
read -p "It's recommended to reboot your system now. Would you like to reboot? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    log_message "Rebooting system..."
    reboot
else
    log_message "Reboot skipped. Please remember to reboot your system later."
fi
