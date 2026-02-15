#!/usr/bin/env bash
# arch-postinstall.sh
# Robustes Arch Linux Postinstall Script
set -euo pipefail

echo "== Start Arch post setup script =="

cd ~

sudo -v

# -----------------------
# 1. System Update
# -----------------------
echo "== Updating system =="
sudo pacman -Syu --noconfirm

# -----------------------
# 2. Download package lists
# -----------------------
echo "== Downloading package lists =="
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqen-content.txt
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqem-content.txt

# -----------------------
# 3. Install repository packages
# -----------------------
echo "== Installing repository packages =="
sudo pacman -S --needed --noconfirm - < Qqen-content.txt

# -----------------------
# 4. Install yay (AUR helper)
# -----------------------
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

# -----------------------
# 5. Install AUR packages
# -----------------------
echo "== Installing AUR packages =="
yay -S --needed --noconfirm - < Qqem-content.txt

# -----------------------
# 6. Cleanup package lists
# -----------------------
rm -f Qqen-content.txt Qqem-content.txt

# -----------------------
# 7. Linutil (optional)
# -----------------------
if command -v linutil &>/dev/null; then
    echo "== Running linutil =="
    curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/linutil_config.toml
    linutil -c ./linutil_config.toml --bypass-root
    rm -f linutil_config.toml
else
    echo "Linutil not installed – skipping"
fi

# -----------------------
# 8. Configure fastfetch / hyfetch
# -----------------------
echo "== Configuring fastfetch / hyfetch =="
mkdir -p ~/.config/fastfetch
curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/config.jsonc \
    -o ~/.config/fastfetch/config.jsonc

if ! command -v hyfetch >/dev/null 2>&1; then
    echo "hyfetch is not installed and fastfetch is used as fallback."
else
    BASHRC="$HOME/.bashrc"
    cp "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d%H%M%S)"

    if grep -q '^[[:space:]]*if \[ -f /usr/bin/fastfetch \]; then' "$BASHRC"; then
        sed -i '/^[[:space:]]*if \[ -f \/usr\/bin\/fastfetch \]; then/,/^[[:space:]]*fi/{
            s|^[[:space:]]*if \[ -f \/usr\/bin\/fastfetch \]; then|if [ -f /usr/bin/hyfetch ]; then|
            s|^[[:space:]]*fastfetch|    hyfetch|
            s|^[[:space:]]*fi|elif [ -f /usr/bin/fastfetch ]; then\n    fastfetch\nfi|
        }' "$BASHRC"

        printf "Set hyfetch as default system information tool for terminal\n"
    else
        echo "Kein fastfetch-Block in .bashrc gefunden. Nichts geändert."
    fi
fi

# -----------------------
# 9. Pacman configuration
# -----------------------
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
fi

# -----------------------
# 10. GNOME Extensions (optional)
# -----------------------
if pgrep -x gnome-shell >/dev/null; then
    echo "== Installing GNOME extensions =="
    TMP_DIR="$HOME/gnome-extensions-temp"
    mkdir -p "$TMP_DIR"
#     https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v71.shell-extension.zip
    extensions=(
        "dash-to-dock@micxgx.gmail.com|71"
        "tiling-assistant@leleat-on-github|54"
    )

    for ext in "${extensions[@]}"; do
        IFS="|" read -r uuid version <<< "$ext"
        uuidWithoutAt="${uuid//@/}" 
        ZIP_FILE="$TMP_DIR/$uuidWithoutAt.v${version}.shell-extension.zip"
        echo $ZIP_FILE
        URL="https://extensions.gnome.org/extension-data/${uuidWithoutAt}.v${version}.shell-extension.zip"
        echo $URL
        echo "Downloading $uuid ..."
        if ! wget -q -O "$ZIP_FILE" "$URL"; then
            echo "Download von $uuid fehlgeschlagen, überspringe..."
            continue
        fi

        if ! gnome-extensions info "$uuid" >/dev/null 2>&1; then
            echo "Installing $uuid ..."
            gnome-extensions install "$ZIP_FILE" --force || echo "Install fehlgeschlagen, evtl. schon installiert"
        fi
        gnome-extensions enable "$uuid" || echo "Enable für $uuid fehlgeschlagen"
    done

    echo "Currently active GNOME extensions:"
    gnome-extensions list
    rm -rf "$TMP_DIR"

    echo "== Loading GNOME dconf settings =="
    if curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/gnome-settings.dconf -o gnome-settings.dconf; then
        dconf load / < gnome-settings.dconf
        rm -f gnome-settings.dconf
    else
        echo "dconf settings download fehlgeschlagen"
    fi
else
    echo "GNOME Shell not running – skipping GNOME extensions and settings"
fi


echo -e "\n\e[32mArch postinstall script finished successfully\e[0m"
read -p "Press Enter to exit..."
