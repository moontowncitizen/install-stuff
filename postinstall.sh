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

# Copy Config and Icons and Pictures and Fonts
cp -rv /home/leigh/git/install-stuff/.config /home/leigh/
cp -rv /home/leigh/git/install-stuff/.icons /home/leigh/
cp -rv /home/leigh/git/install-stuff/Pictures/ /home/leigh/
cp -rv /home/leigh/git/install-stuff/.fonts/ /home/leigh
fc-cache -fv

# Install cli pride flags
cd
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

# Install fragments
sudo dnf install fragments -y

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
sudo flatpak install atom

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

# install chris titus script
cd git
git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git
cd mybash
chmod +x setup.sh
./setup.sh
cd

# Notify user of completion
echo "all done leigh!"
