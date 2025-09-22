#!/bin/bash

# Automatic Dotfiles setup
# Will create symlinks for all files for the current user
# Run also for root user to setup root dotfiles

set -euo pipefail

# cd to script directory
cd "$(dirname "$0")"

# Häufig verwendete Hilfsfunktionen für Fehler, z.B. hier: https://stackoverflow.com/a/25515370/13565664, https://stackoverflow.com/a/7869048/13565664
say() {
    local color=$1; shift
    if [[ -t 1 ]]; then
        echo -e "\e[${color}m$0: $*\e[0m"
    else
        echo "$0: $*"
    fi
}
info() { say 32 "$*"; }
yell() { say 31 "$*" >&2; }
die() { yell "$*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Bitte als root ausführen!"
[[ $# -ge 1 ]] || die "Usage: $0 <user1> [<user2> ...]"

users=("$@")
for a in "${users[@]}"; do
    id "$a" &>/dev/null || die "User $a existiert nicht!"
done

# Installiere hilfreiche Pakete
packages=(
    neofetch  # Zeige Systeminfos an (OS, CPU, RAM, etc.)
    htop      # Prozess-Explorer als TUI
    tmux      # Virtuelle Terminals, die unabh. von SSH weiter laufen
    fzf       # Fuzzy finder. Dependency für neovim.
    git       # Versionskontrolle
    unzip     # Extrahiere Zip-Archive
    xxd       # Hex-viewer für command line
    rsync     # Copy-Tool, das nur Änderungen kopiert. Dependency für backupProgram.
    jq        # Formatiere, lese und bearbeite JSON-Dateien. Dependency für backupProgram.
    curl      # HTTP-Client für Command-Line (Datei runterladen, Web-APIs benutzen, Web-Server testen, etc.)
    nmap      # Portscanner
    cmake     # Build-Tool
)
packages_ubuntu_wsl=(
    libfuse2 # Für nvim AppImage
)
packages_fedora=(
    fuse # Für nvim AppImage
)
if grep -q Ubuntu </etc/os-release && uname -r | grep -q WSL; then
    info installing packages for Ubuntu
    apt-get update
    apt-get install -y "${packages[@]}" "${packages_ubuntu_wsl[@]}"
    apt-get upgrade -y
elif [[ -f /etc/debian_version ]]; then
    info installing packages for Debian
    apt-get update
    apt-get install -y "${packages[@]}"
    apt-get upgrade -y
elif [[ -f /etc/fedora-release ]]; then
    info installing packages for Fedora
    dnf install -y "${packages[@]}"
    dnf upgrade -y
else
    die "Unbekanntes Betriebssystem!"
fi


# bashrc
# ======
# siehe: https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html
# Interaktive Login Shell:
#     - /etc/profile
#       |- /etc/bash.bashrc
#       `- /etc/profile.d/*
#     - ~/.profile
#       `- ~/.bashrc
# Interaktive Non-Login Shell (z.B. sudo -i): direkt ~/.bashrc
# => /etc/profile.d/* ist ein guter Ort für globale Bash-Settings.
# Lege symbolischen Link in /etc/profile.d zu bashrc in diesem Repo an.
# Wird von allen Usern geladen.

ln -sfv "$(pwd)/bashrc.sh" /etc/profile.d/patrick-dotfiles-bashrc.sh

# tmux
# ====
ln -sfv "$(pwd)/tmux.conf" /etc/tmux.conf

# Neovim Installation und config

# Assert nvim is not installed via apt/dnf/pacman
which nvim && [[ $(which nvim) != /usr/local/bin/nvim ]] && die "Neovim ist mit einem Paketmanager installiert. Bitte deinstallieren."

# Lade AppImage herunter (AppImage ist eine einfache executable (elf), die per FUSE als container läuft. Kann wie normale executable verwendet werden.)
curl -L -o /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage \
    || yell Konnte /usr/local/bin/nvim nicht schreiben. Ist neovim aktuell offen?
chmod -v +x /usr/local/bin/nvim # Setzte Ausfürungsrechte


# Lege Symlink zu nvim-Config an, wenn noch keine neovim-Config vorhanden ist.
mkdir -p /root/.config
[[ -d /root/.config/nvim ]] || ln -sfv "$(pwd)/nvim" /root/.config/nvim
for a in "${users[@]}"; do
    sudo -u "$a" mkdir -p "/home/$a/.config"
    [[ -d /home/$a/.config/nvim ]] || ln -sfv "$(pwd)/nvim" "/home/$a/.config/nvim"
done

# Trage in update-alternatives-Liste ein
# Du kannst den Editor dann ändern: sudo update-alternatives --config editor
update-alternatives --install /usr/bin/editor editor /usr/local/bin/nvim 40
