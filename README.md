# Leigh's Silly Fedora Install

<p align="center">This is a Bash script for setting up my environment on a GNU/Linux system, particularly for Fedora-based distributions for the XFCE4 desktop environment. The script automates the installation of essential packages, configuration files, themes, and other tools, with an optional setup for Chromebook Linux audio.</p>

## Features
- **System Updates**: Automatically updates your system using dnf.
- **Directory Setup**: Creates necessary directories for organization.
- **Configuration Files**: Copies your custom configuration files for `.config`, `.icons`, and `.fonts`.
- **Package Installation**:
  - Terminal emulator (kitty)
  - Torrent client (qbittorrent)
  - Office suite (LibreOffice)
  - Password manager (Bitwarden)
  - Music streaming (Spotify)
  - VPN client (Surfshark)
  - DockBarX for XFCE
- **Flatpak and Snap Setup**: Adds repositories and installs applications via Flatpak and Snap.
- **Ulauncher**: Installs Ulauncher, a quick launcher.
- **Editor**: Installs the Pulsar code editor.
- **Theme and Icon Setup**:
  - Installs the Gruvbox GTK Theme and Gruvbox Plus Icon Pack.
  - Sets up GTK theme overrides for Flatpak applications.
- **Chris Titus Tech Setup Script**: Clones and runs a setup script from Chris Titus Tech.
- **Optional Chromebook Audio Setup**: Adds a `-c` flag to set up Chromebook Linux audio.

## Requirements
1. **Fedora-based distribution**: The script is designed with Fedora in mind and uses the dnf package manager.
2. **Git Installed**: You'll need git to clone repositories used in this setup.
3. **Internet Connection**: The script downloads several packages and repositories from the internet.
4. **XFCE4 Panel**: The script checks for the XFCE panel and starts it if not running, ensuring a smooth setup experience.

## Usage
Follow the steps below to set up your environment using this script.

### Running the Script
Clone this repository:
```sh
git clone https://github.com/moontowncitizen/install-stuff.git
```

Make the script executable:
```sh
chmod +x setup.sh
```

Run the script with the desired options:
```sh
./setup.sh [options]
```

| Command-Line Options                             |
|-------------------------------------------------|
| Flag | Description                               |
| -c   | Setup Chromebook Linux Audio.             |
| -d   | Specify desktop environment (default is auto-detected; options: kde, gnome, xfce). |
| -h   | Display help message with usage information |

To run the standard setup with Chromebook audio:
```sh
./setup.sh -c
```

To view the help message:
```sh
./setup.sh -h
```

To specify the desktop environment as XFCE:
```sh
./setup.sh -d xfce
```

### Note
Make sure that your XFCE panel is running before executing the script, or let the script handle starting it for you.
