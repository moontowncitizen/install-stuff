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
LOG_FILE="/tmp/fedora_setup_$(date +%Y%m%d_%H%M%S).log"
DOCKLIKE_RPM="$INSTALL_STUFF_REPO/rpms/xfce4-docklike-plugin-0.4.2-1.fc40.x86_64.rpm"

# Flags
CHROMEBOOK_AUDIO_SETUP=false
DESKTOP_ENVIRONMENT=""
INSTALL_MYBASH=false
UNINSTALL=false

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

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
        log_message "Installing $1..."
        sudo dnf install "$1" -y
    else
        log_message "$1 is already installed."
    fi
}

# Function to uninstall a package using DNF
uninstall_dnf_package() {
    if dnf list installed "$1" &>/dev/null; then
        log_message "Uninstalling $1..."
        sudo dnf remove "$1" -y
    else
        log_message "$1 is not installed."
    fi
}

# Function to perform uninstallation
perform_uninstall() {
    log_message "Starting uninstallation process..."

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
    uninstall_dnf_package "cmake"
    uninstall_dnf_package "libtool"
    uninstall_dnf_package "xfce4-docklike-plugin"
    uninstall_dnf_package "gnome-tweaks"
    uninstall_dnf_package "gnome-shell-extension-dash-to-dock"

    # Remove the cloned repositories and configuration files
    log_message "Removing configuration and theme files..."
    rm -rf "$GIT_DIR/mybash" "$GIT_DIR/chromebook-linux-audio" "$THEMES_DIR" "$ICONS_DIR"

    log_message "Uninstallation completed!"
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
        log_message "Unable to detect desktop environment. Please specify with the -d option."
        usage
    fi
}

# Function to set the desktop background
set_desktop_background() {
    if [[ ! -f "$BACKGROUND_IMAGE" ]]; then
        log_message "Warning: Background image not found at $BACKGROUND_IMAGE"
        return 1
    fi

    case "$DESKTOP_ENVIRONMENT" in
        kde)
            if command_exists kwriteconfig5; then
                kwriteconfig5 --file "$(kreadconfig5 --file kiwin --key SystemSettings)" --group "Wallpaper" --key "Image" "$BACKGROUND_IMAGE"
            else
                log_message "Warning: kwriteconfig5 not found. Unable to set KDE background."
            fi
            ;;
        gnome)
            if command_exists gsettings; then
                gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_IMAGE"
            else
                log_message "Warning: gsettings not found. Unable to set GNOME background."
            fi
            ;;
        xfce)
            if command_exists xfconf-query; then
                xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$BACKGROUND_IMAGE"
            else
                log_message "Warning: xfconf-query not found. Unable to set XFCE background."
            fi
            ;;
    esac
}

# Function to install Starship
install_starship() {
    if ! command_exists starship; then
        log_message "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh
        echo 'eval "$(starship init bash)"' >> "$HOME_DIR/.bashrc"
        log_message "Starship installed successfully."
    else
        log_message "Starship is already installed."
    fi
}

# Function to install MyBash
install_mybash() {
    log_message "Installing MyBash from Chris Titus Tech..."
    git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git "$GIT_DIR/mybash"
    pushd "$GIT_DIR/mybash" || exit 1
    chmod +x setup.sh
    ./setup.sh
    popd || exit 1
    log_message "MyBash installation completed."
}

# Function to install CLI Pride Flags
install_cli_pride_flags() {
    log_message "Installing Node.js and CLI Pride Flags..."
    install_dnf_package "nodejs"
    if command_exists npm; then
        sudo npm install -g cli-pride-flags
    else
        log_message "Warning: npm not found after installing Node.js. Unable to install cli-pride-flags."
    fi
}

# Function to check and install Git
ensure_git_installed() {
    if ! command_exists git; then
        log_message "Git not found. Installing Git..."
        install_dnf_package "git"
    fi
}

# Function to install xfce4-docklike-plugin RPM
install_xfce_docklike_plugin() {
    if [ "$DESKTOP_ENVIRONMENT" = "xfce" ]; then
        if [ -f "$DOCKLIKE_RPM" ]; then
            log_message "Installing xfce4-docklike-plugin RPM..."
            sudo dnf install "$DOCKLIKE_RPM" -y
        else
            log_message "Warning: xfce4-docklike-plugin RPM not found at $DOCKLIKE_RPM"
        fi
    fi
}


# Function to install GNOME-specific packages and extensions
install_gnome_packages() {
    if [ "$DESKTOP_ENVIRONMENT" = "gnome" ]; then
        log_message "Installing GNOME-specific packages and extensions..."
        install_dnf_package "gnome-tweaks"
        install_dnf_package "gnome-shell-extension-dash-to-dock"

        # Enable Dash to Dock extension
        gnome-extensions enable dash-to-dock@micxgx.gmail.com

        log_message "GNOME-specific installations completed."
    fi
}

# Function to install X Window system development files
install_x11_development_files() {
    log_message "Installing X Window system libraries and header files..."
    sudo dnf groupinstall "X Software Development" -y
    sudo dnf install xorg-x11-server-devel libX11-devel libXtst-devel libXrandr-devel -y
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

# Start logging
log_message "Starting Fedora setup script"

# Install X11 development files (needed for graphical environments)
install_x11_development_files

# If uninstall flag is set, perform uninstallation
if [ "$UNINSTALL" = true ]; then
    perform_uninstall
fi

# Detect desktop environment if not specified
if [ -z "$DESKTOP_ENVIRONMENT" ]; then
    detect_desktop_environment
fi

# Install Chromebook audio setup if requested
if [ "$CHROMEBOOK_AUDIO_SETUP" = true ]; then
    log_message "Setting up Chromebook Linux audio..."
    ensure_git_installed
    git clone --depth=1 https://github.com/WeirdTreeThing/chromebook-linux-audio.git "$GIT_DIR/chromebook-linux-audio"
    pushd "$GIT_DIR/chromebook-linux-audio" || exit 1
    chmod +x setup-audio.sh
    sudo ./setup-audio.sh
    popd || exit 1
    log_message "Chromebook Linux audio setup completed."
fi

# Install MyBash from Chris Titus Tech if requested
if [ "$INSTALL_MYBASH" = true ]; then
    install_mybash
fi

# Install CLI Pride Flags
install_cli_pride_flags

# Set desktop background
set_desktop_background

# Install Starship
install_starship

#Install Pulsar
cd
cd git
cd install-stuff
cd rpms
curl -L -o pulsar.rpm "https://download.pulsar-edit.dev/?os=linux&type=linux_rpm" && sudo rpm -i pulsar.rpm

# Install XFCE docklike plugin if applicable
install_xfce_docklike_plugin

# Install GNOME-specific packages and extensions if applicable
install_gnome_packages

# Completion Notification
log_message "All done, $(whoami)! Your Fedora Linux setup is complete. Yippee!"

log_message "Setup completed. Log file: $LOG_FILE"
