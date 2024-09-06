#!/bin/bash

# Create a git folder
mkdir git
cd

# Create an overlord folder
mkdir Desktop
cd Desktop
mkdir overlord
cd overlord
mkdir partial
mkdir torrents
cd

# Update system packages
sudo dnf update -y

# Copy Config and Icons
cp -rv /home/leigh/install-stuff/.config /home/leigh/
cp -rv /home/leigh/install-stuff/.icons /home/leigh/

# Install cli pride flags
cd git
sudo dnf install nodejs -y
npm i -g cli-pride-flags
cd

# Wallpaper
WALLPAPER_PATH="/home/leigh/install-stuff/Pictures/gruvbox/gruvbox_random.png"
gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"

# Install Kitty
sudo dnf install kitty -y

# Install Snapd
sudo dnf install snapd -y
sudo ln -s /var/lib/snapd/snap /snap
sudo systemctl enable --now snapd.socket

# Install Gnome Tweaks
sudo dnf install gnome-tweaks -y

# Install Gnome Calendar
sudo dnf install gnome-calendar -y

# Install qBittorrent
sudo dnf install qbittorrent -y

# Install LibreOffice
sudo dnf install libreoffice -y

# Install Surfshark (beta version via Snap)
sudo snap install surfshark --beta

# Install Flatpak
sudo dnf install flatpak -y
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Spotify via Flatpak
sudo flatpak install flathub com.spotify.Client -y

# Install Bitwarden via Flatpak
sudo flatpak install flathub com.bitwarden.desktop -y

# Install Icons
cd git
git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git
cd gruvbox-plus-icon-pack
cp -rv Gruvbox-Plus-Dark ~/.local/share/icons
cd

# Install GTK theme
sudo dnf install gtk-murrine-engine
cd git
git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git
cd Gruvbox-GTK-Theme
cd themes
sudo ./install.sh --tweak moon mac outline float -t green -l
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
flatpak override --user --filesystem=xdg-config/gtk-4.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0
gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Dark-B-LB"
cd

# Install Fonts
FONT_SOURCE="/home/leigh/install-stuff/fonts/"
FONT_DEST="$HOME/.local/share/fonts/"
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
echo "
 _          _          _          _       _      _     _   _             __               _                _
| |        | |        | |        | |     | |    | |   | | | |           / _|             | |              (_)
| |__   ___| |__   ___| |__   ___| |__   | | ___| |_  | |_| |__   ___  | |_ _   _ _ __   | |__   ___  __ _ _ _ __
| '_ \ / _ \ '_ \ / _ \ '_ \ / _ \ '_ \  | |/ _ \ __| | __| '_ \ / _ \ |  _| | | | '_ \  | '_ \ / _ \/ _` | | '_ \
| | | |  __/ | | |  __/ | | |  __/ | | | | |  __/ |_  | |_| | | |  __/ | | | |_| | | | | | |_) |  __/ (_| | | | | |
|_| |_|\___|_| |_|\___|_| |_|\___|_| |_| |_|\___|\__|  \__|_| |_|\___| |_|  \__,_|_| |_| |_.__/ \___|\__, |_|_| |_|
                                                                                                      __/ |
                                                                                                     |___/         "
