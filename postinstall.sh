#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo dnf distro-sync --refresh -y

# Create an overlord folder
mkdir Desktop
cd Desktop
mkdir overlord
cd overlord
mkdir partial
mkdir torrents
cd

# Set desktop background
BACKGROUND_PATH="/home/leigh/git/install-stuff/Pictures/gruvbox/gruvbox_random.png"  # Replace with the full path to your image
if [ -f "$BACKGROUND_PATH" ]; then
    echo "Changing desktop background..."
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$BACKGROUND_PATH"
else
    echo "Background image not found at $BACKGROUND_PATH."
fi

# Copy Config and Icons and Pictures
cp -rv /home/leigh/git/install-stuff/.config /home/leigh/
cp -rv /home/leigh/git/install-stuff/.icons /home/leigh/
cp -rv /home/leigh/git/install-stuff/Pictures/ /home/leigh/

# Install cli pride flags
cd git
sudo dnf install nodejs -y
npm i -g cli-pride-flags
cd

# Install Kitty
sudo dnf install kitty -y

# Install Snapd
sudo dnf install snapd -y
sudo ln -s /var/lib/snapd/snap /snap
sudo systemctl enable --now snapd.socket

# Install qBittorrent
sudo dnf install qbittorrent -y

# Install LibreOffice
sudo dnf install libreoffice -y

# Install Surfshark (beta version via Snap)
sudo snap refresh
sudo snap install surfshark --beta

# Install Flatpak
sudo dnf install flatpak -y
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Spotify via Flatpak
sudo flatpak install flathub com.spotify.Client -y

# Install Bitwarden via Flatpak
sudo flatpak install flathub com.bitwarden.desktop -y

# Install Ulauncher
if ! command_exists ulauncher; then
    echo "Installing Ulauncher..."
    sudo dnf install ulauncher -y
else
    echo "Ulauncher is already installed."
fi

# Install Plank dock
if ! command_exists plank; then
    echo "Installing Plank..."
    sudo dnf install plank -y
else
    echo "Plank is already installed."
fi

# Install atom
sudo rpm --import https://packagecloud.io/AtomEditor/atom/gpgkey
sudo sh -c 'echo -e "[Atom]\nname=Atom Editor\nbaseurl=https://packagecloud.io/AtomEditor/atom/el/7/\$basearch\nenabled=1\ngpgcheck=0\nrepo_gpgcheck=1\ngpgkey=https://packagecloud.io/AtomEditor/atom/gpgkey" > /etc/yum.repos.d/atom.repo'
sudo dnf install atom

# Install Icons
cd git
git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git
cd gruvbox-plus-icon-pack
cp -rv Gruvbox-Plus-Dark ~/.local/share/icons
cd

# Install GTK theme
sudo dnf install gtk-murrine-engine -y
cd git
git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git
cd Gruvbox-GTK-Theme
cd themes
sudo ./install.sh -l -t green -c dark --tweaks float outline
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
flatpak override --user --filesystem=xdg-config/gtk-4.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0
gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Dark-B-LB"
cd

# Install Fonts
mkdir /home/leigh/.fonts/
FONT_SOURCE="/home/leigh/git/install-stuff/fonts/"
FONT_DEST="$HOME/.fonts/"
mkdir -p "$FONT_DEST"
echo "Copying fonts from $FONT_SOURCE to $FONT_DEST..."
cp "$FONT_SOURCE"*.ttf "$FONT_DEST"
cp "$FONT_SOURCE"*.otf "$FONT_DEST"
echo "Updating font cache..."
fc-cache -fv
echo "Installed fonts:"
fc-list | grep -i "Fira\|Hurmit\|Monofur\|Trap"

# install chris titus script
cd git
git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git
cd mybash
chmod +x setup.sh
./setup.sh
cd

# Notify user of completion
echo " all done leigh!"
