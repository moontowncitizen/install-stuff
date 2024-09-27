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
INSTALL_KDE_THEMES=false
INSTALL_XFCE=true  # Set to true by default for XFCE Fedora 40

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -c    Install Chromebook audio setup
  -k    Install KDE Plasma theming and additional packages
  -x    Install XFCE-specific packages and configurations (default: enabled)
  -h    Display this help message

Example:
  $0 -c    Install Chromebook audio with default XFCE setup
EOF
    exit 1
}

# Parse command-line options
while getopts ":ckhx" opt; do
  case ${opt} in
    c ) INSTALL_CHROMEBOOK_AUDIO=true ;;
    k ) INSTALL_KDE_THEMES=true ;;
    x ) INSTALL_XFCE=true ;;
    h ) usage ;;
    \? ) echo "Invalid option: $OPTARG" 1>&2; usage ;;
  esac
done

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package using DNF if not already installed
install_dnf_package() {
    if ! rpm -q "$1" &>/dev/null; then
        log_message "Installing $1..."
        sudo dnf install "$1" -y || log_message "Warning: Failed to install $1"
    else
        log_message "$1 is already installed."
    fi
}

# Function to update the system
update_system() {
    log_message "Updating system packages..."
    sudo dnf distro-sync --refresh -y || log_message "Warning: System update failed"
}

# Function to create necessary directories
create_directories() {
    log_message "Creating necessary directories..."
    mkdir -p "$GIT_DIR" "$DESKTOP_DIR" "$OVERLORD_DIR" "$DOWNLOADS_DIR" "$THEMES_DIR" "$ICONS_DIR"
}

# Function to install Chromebook audio setup
install_chromebook_audio() {
    log_message "Setting up Chromebook Linux audio..."
    if ! git clone https://github.com/WeirdTreeThing/chromebook-linux-audio.git "$GIT_DIR/chromebook-linux-audio"; then
        log_message "Error: Failed to clone chromebook-linux-audio repository"
    else
        pushd "$GIT_DIR/chromebook-linux-audio" || return
        chmod +x setup-audio
        ./setup-audio || log_message "Warning: Failed to run setup-audio script"
        popd || return
    fi
}

# Function to install KDE Plasma theming
install_kde_plasma_theming() {
    log_message "Installing KDE Plasma theming..."

    local dirs=(
        "$HOME_DIR/.local/share/aurorae"
        "$HOME_DIR/.local/share/backgrounds"
        "$HOME_DIR/.local/share/plasma"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        cp -R "$INSTALL_STUFF_REPO/${dir#$HOME_DIR/}/"* "$dir/" 2>/dev/null || log_message "Warning: Failed to copy to $dir"
    done

    log_message "KDE Plasma theming installation completed."
}

# Function to install additional KDE packages
install_additional_kde_packages() {
    log_message "Installing Haruna, Lutris, and Steam..."

    # Enable RPM Fusion repositories if not already enabled
    if ! dnf repolist | grep -q "rpmfusion-free"; then
        sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
    fi

    # Install packages
    local kde_packages=("haruna" "lutris" "steam")
    for package in "${kde_packages[@]}"; do
        install_dnf_package "$package"
    done

    log_message "Additional KDE packages installation completed."
}

# Function to install XFCE-specific packages and configurations
install_xfce() {
    log_message "Installing XFCE-specific packages and configurations..."

    # Install XFCE-specific packages
    local xfce_packages=(
        "xfce4-panel" "xfce4-session" "xfce4-settings" "xfdesktop"
        "xfwm4" "xfce4-terminal" "thunar" "xfce4-appfinder"
        "xfce4-power-manager" "xfce4-notifyd" "xfce4-screenshooter"
        "xfce4-taskmanager" "xfce4-whiskermenu-plugin" "xfce4-pulseaudio-plugin"
    )
    for package in "${xfce_packages[@]}"; do
        install_dnf_package "$package"
    done

    # Install and configure xfce4-docklike-plugin
    log_message "Installing xfce4-docklike-plugin..."
    if [ -f "$DOCKLIKE_RPM" ]; then
        sudo rpm -i "$DOCKLIKE_RPM" || log_message "Warning: Failed to install xfce4-docklike-plugin"
    else
        log_message "Warning: xfce4-docklike-plugin RPM not found at $DOCKLIKE_RPM"
    fi

    # Copy XFCE-specific configuration files
    log_message "Copying XFCE configuration files..."
    cp -rv "$INSTALL_STUFF_REPO/.config/xfce4" "$HOME_DIR/.config/" || log_message "Warning: Failed to copy XFCE config files"

    # Set XFCE-specific desktop background
    if [ -f "$BACKGROUND_IMAGE" ]; then
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$BACKGROUND_IMAGE"
    else
        log_message "Warning: Background image not found at $BACKGROUND_IMAGE"
    fi

    log_message "XFCE-specific setup completed."
}

# Function to set desktop background
set_desktop_background() {
    log_message "Setting desktop background..."
    if [ -f "$BACKGROUND_IMAGE" ]; then
        if [ "$INSTALL_XFCE" = true ]; then
            xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$BACKGROUND_IMAGE"
        elif [ "$INSTALL_KDE_THEMES" = true ]; then
            plasma-apply-wallpaperimage "$BACKGROUND_IMAGE"
        else
            log_message "Warning: Desktop environment not specified. Skipping background setting."
        fi
    else
        log_message "Warning: Background image not found at $BACKGROUND_IMAGE"
    fi
}

# Function to install common applications
install_common_apps() {
    log_message "Installing common applications..."
    common_apps=(
        "sassc" "libsass" "nodejs" "kitty" "snapd" "qbittorrent" "libreoffice"
        "gtk-murrine-engine" "ulauncher" "cmake" "libtool" "clapper" "git"
        "curl" "wget" "vim" "nano" "htop" "starship" "bash-completion" "fastfetch"
        "chromium" "flatpak" "flathub" "kde-connect"
    )
    for app in "${common_apps[@]}"; do
        install_dnf_package "$app"
    done
}

# Function to install Flatpak applications
install_flatpak_apps() {
    log_message "Installing Flatpak applications..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y bitwarden spotify || log_message "Warning: Failed to install Flatpak applications"
}

# Function to set up Snap
setup_snap() {
    log_message "Setting up Snap..."
    sudo systemctl enable --now snapd.socket || log_message "Warning: Failed to enable snapd.socket"
    sudo ln -sf /var/lib/snapd/snap /snap || log_message "Warning: Failed to create snap symlink"
    sudo snap refresh || log_message "Warning: Failed to refresh snap"
    sudo snap install surfshark --edge || log_message "Warning: Failed to install Surfshark"
}

# Function to install MyBash
install_mybash() {
    log_message "Installing MyBash..."
    pushd "$GIT_DIR" || return
    git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git
    cd mybash || return
    chmod +x setup.sh
    ./setup.sh
    popd || return
}

# Function to install CLI Pride Flags
install_cli_pride_flags() {
    log_message "Installing CLI Pride Flags..."
    if command_exists npm; then
        npm i -g cli-pride-flags || log_message "Warning: Failed to install CLI Pride Flags"
    else
        log_message "Warning: npm not found. Skipping CLI Pride Flags installation."
    fi
}

# Function to install Pulsar
install_pulsar() {
    log_message "Installing Pulsar..."
    pushd "$INSTALL_STUFF_REPO/rpms" || return
    if ! curl -L -o pulsar.rpm "https://download.pulsar-edit.dev/?os=linux&type=linux_rpm"; then
        log_message "Error: Failed to download Pulsar RPM"
    else
        sudo rpm -i pulsar.rpm || log_message "Warning: Failed to install Pulsar RPM"
    fi
    popd || return
}

# Function to install icons
install_icons() {
    log_message "Installing Gruvbox Plus icons..."
    pushd "$GIT_DIR" || return
    if ! curl -L -o gruvbox-plus-icons.zip https://github.com/SylEleuth/gruvbox-plus-icon-pack/releases/download/v5.5.0/gruvbox-plus-icon-pack-5.5.0.zip; then
        log_message "Error: Failed to download Gruvbox Plus icons"
    else
        unzip -o gruvbox-plus-icons.zip -d "$HOME_DIR/.local/share/icons/" || log_message "Warning: Failed to extract icons to .local/share/icons"
        unzip -o gruvbox-plus-icons.zip -d "$HOME_DIR/.icons/" || log_message "Warning: Failed to extract icons to .icons"
    fi
    popd || return

    log_message "Installing Tela Dark Icons..."
    pushd "$GIT_DIR" || return
    if ! git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git; then
        log_message "Error: Failed to clone Tela-circle-icon-theme repository"
    else
        cd Tela-circle-icon-theme || return
        sudo chmod +x install.sh
        ./install.sh || log_message "Warning: Failed to install Tela Dark Icons"
    fi
    popd || return
}

# Function to install GTK themes
install_gtk_themes() {
    log_message "Installing GTK themes..."
    pushd "$GIT_DIR" || return
    if ! git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git; then
        log_message "Error: Failed to clone Gruvbox-GTK-Theme repository"
    else
        cd Gruvbox-GTK-Theme/themes || return
        ./install.sh --tweaks outline float -t green -l -c dark || log_message "Warning: Failed to install GTK themes"
    fi
    popd || return
}

# Function to set Flatpak overrides
set_flatpak_overrides() {
    log_message "Setting Flatpak overrides..."
    flatpak override --user --filesystem="$HOME_DIR/.themes" || log_message "Warning: Failed to set Flatpak override for .themes"
    flatpak override --user --filesystem="$HOME_DIR/.icons" || log_message "Warning: Failed to set Flatpak override for .icons"
    flatpak override --user --filesystem=xdg-config/gtk-4.0 || log_message "Warning: Failed to set Flatpak override for gtk-4.0"
}

# Main execution starts here
log_message "Starting Fedora 40 XFCE setup script"

# Check for sufficient disk space (e.g., 10GB free)
free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$free_space" -lt 10 ]; then
    log_message "Error: Insufficient disk space. At least 10GB free space is required."
    exit 1
fi

update_system
create_directories

# Copy configuration files
log_message "Copying configuration files..."
cp -rv "$INSTALL_STUFF_REPO/.config" "$HOME_DIR/" 2>/dev/null || log_message "Warning: Failed to copy .config"
cp -rv "$INSTALL_STUFF_REPO/.fonts" "$HOME_DIR/" 2>/dev/null || log_message "Warning: Failed to copy .fonts"
cp -rv "$INSTALL_STUFF_REPO/.icons" "$HOME_DIR/" 2>/dev/null || log_message "Warning: Failed to copy .icons"
cp -rv "$INSTALL_STUFF_REPO/Pictures" "$HOME_DIR/" 2>/dev/null || log_message "Warning: Failed to copy Pictures"

install_common_apps
install_flatpak_apps
setup_snap

# Install Chromebook audio setup if flag is set
if [ "$INSTALL_CHROMEBOOK_AUDIO" = true ]; then
    install_chromebook_audio
fi

install_mybash
install_cli_pride_flags
install_pulsar
install_icons
install_gtk_themes

# Install XFCE-specific packages and configurations
if [ "$INSTALL_XFCE" = true ]; then
    install_xfce
fi

# Set desktop background
set_desktop_background

# Set correct permissions for the home directory
sudo chown -R "$SUDO_USER:$SUDO_USER" "$HOME_DIR"

# Completion Notification
log_message "All done, $SUDO_USER! Your Fedora 40 XFCE setup is complete. Yippee!"
log_message "Setup completed. Log file: $LOG_FILE"

# Prompt for reboot
read -p "It's recommended to reboot your system now. Would you like to reboot? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
