#!/usr/bin/env bash
# arch-postinstall.sh
# Führt alle Post-Install Schritte auf Arch Linux aus
set -euo pipefail

echo "== Start Arch post setup script =="

cd ~

sudo -v

# System update
echo "== Updating system =="
sudo pacman -Syu --noconfirm

# Download package lists
echo "== Downloading package lists =="
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqen-content.txt
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqem-content.txt

# Install repo packages
echo "== Installing repository packages =="
sudo pacman -S --needed --noconfirm - < Qqen-content.txt

# Install yay (AUR helper)
if ! command -v yay &>/dev/null; then
    echo "== Installing yay =="
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$tmpdir"
fi

yay --version

# Install AUR packages
echo "== Installing AUR packages =="
yay -S --needed --noconfirm - < Qqem-content.txt

# Cleanup package lists
rm -f Qqen-content.txt Qqem-content.txt

# Linutil
echo "== Running linutil =="
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/linutil_config.toml
linutil -c ./linutil_config.toml --bypass-root
rm -f linutil_config.toml

# Configure fastfetch
echo "== Configuring fastfetch =="
mkdir -p ~/.config/fastfetch
curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/config.jsonc \
    -o ~/.config/fastfetch/config.jsonc

# Hyfetch fallback
BASHRC="$HOME/.bashrc"
cp "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d%H%M%S)"

if grep -q '^[[:space:]]*if \[ -f /usr/bin/fastfetch \]; then' "$BASHRC"; then
    sed -i '/^[[:space:]]*if \[ -f \/usr\/bin\/fastfetch \]; then/,/^[[:space:]]*fi/{
        s|^[[:space:]]*if \[ -f \/usr\/bin\/fastfetch \]; then|if [ -f /usr/bin/hyfetch ]; then|
        s|^[[:space:]]*fastfetch|    hyfetch|
        s|^[[:space:]]*fi|elif [ -f /usr/bin/fastfetch ]; then\n    fastfetch\nfi|
    }' "$BASHRC"
    echo "Set hyfetch as default terminal info tool"
else
    echo "No fastfetch block in .bashrc found."
fi

# Pacman configuration
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
fi

# GNOME extensions
TMP_DIR="$HOME/gnome-extensions-temp"
mkdir -p "$TMP_DIR"

extensions=(
    "dash-to-dock@micxgx.gmail.com|70"
    "tiling-assistant@leleat-on-github|70"
)

echo "== Installing GNOME extensions =="
for ext in "${extensions[@]}"; do
    IFS="|" read -r uuid version <<< "$ext"
    ZIP_FILE="$TMP_DIR/$uuid.zip"
    URL="https://extensions.gnome.org/extension-data/${uuid}.v${version}.shell-extension.zip"

    echo "Downloading $uuid ..."
    wget -q -O "$ZIP_FILE" "$URL"

    echo "Installing $uuid ..."
    gnome-extensions install "$ZIP_FILE" || echo "Extension $uuid möglicherweise schon installiert"
    gnome-extensions enable "$uuid"
done

echo "Currently active GNOME extensions:"
gnome-extensions list
rm -rf "$TMP_DIR"

# Load GNOME settings
curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/gnome-settings.dconf \
    -o gnome-settings.dconf
dconf load / < gnome-settings.dconf
rm -f gnome-settings.dconf

echo -e "\n\e[32mScript finished\e[0m"
read -p "Press Enter to exit..."
