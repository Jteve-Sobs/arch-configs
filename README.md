# archinstall configuration script
After launching Arch ISO with internet access

```bash
archinstall --config https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/user_configuration.json
```

# Install all packages in list and update system

```bash

#!/usr/bin/env bash
set -euo pipefail

echo "== Start Arch post setup script =="

cd ~

sudo -v

# System update
sudo pacman -Syu --noconfirm

# Download package lists
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqen-content.txt
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqem-content.txt

# Install repo packages
sudo pacman -S --needed --noconfirm - < Qqen-content.txt

# Install yay only if not installed
if ! command -v yay &>/dev/null; then
    echo "Installing yay..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$tmpdir"
fi

yay --version

# Install AUR packages
yay -S --needed --noconfirm - < Qqem-content.txt

# Cleanup package lists
rm -f Qqen-content.txt Qqem-content.txt

# Linutil
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/linutil_config.toml
linutil -c ./linutil_config.toml --bypass-root
rm -f linutil_config.toml

# Configure fastfetch
mkdir -p ~/.config/fastfetch
curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/config.jsonc \
-o ~/.config/fastfetch/config.jsonc

# pacman config
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
fi

printf "\n\e[32mScript finished\e[0m\n"

```

Gnome extensions:  
[Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)  
[Tiling Assistant](https://extensions.gnome.org/extension/3733/tiling-assistant/)
