#!/usr/bin/env bash
# arch-postinstall.sh
# Robustes Arch Linux Postinstall Script
set -euo pipefail

start_time=$(date +%s)

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

curl -fsSL -o ~/.config/hyfetch.json \
https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/hyfetch.json

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

        echo "Set hyfetch as default system information tool for terminal\n"
    else
        echo "Kein fastfetch-Block in .bashrc gefunden. Nichts geändert."
    fi
fi

# -----------------------
# 9. Pacman configuration
# -----------------------
echo "== Configuring pacman =="
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

    echo ""
    echo "Installed GNOME extensions:"
    gnome-extensions list

    echo ""
    echo "Currently active GNOME extensions:"
    gnome-extensions list --active
    echo ""

    rm -rf "$TMP_DIR"

    echo "== Loading GNOME dconf settings =="
    if curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/gnome-settings.dconf -o gnome-settings.dconf; then
        dconf load / < gnome-settings.dconf

        echo "Log off to enable settings"

        rm -f gnome-settings.dconf
    else
        echo "dconf settings download fehlgeschlagen"
    fi
else
    echo "GNOME Shell not running – skipping GNOME extensions and settings"
fi

# -----------------------
# 11. Enable docker and start it
# -----------------------
echo "== Docker configuration =="

sudo systemctl enable --now docker

sudo systemctl status docker

echo "Current group assignments"
groups

# -----------------------
# 12. Set Firefox language to german
# -----------------------
echo "== Configuring Firefox language to German =="

# 1️⃣ Check Firefox
if ! command -v firefox >/dev/null 2>&1; then
    echo "[ERROR] Firefox not installed. Skipping language setup."
else
    echo "[INFO] Firefox found: $(command -v firefox)"
fi

# 2️⃣ Install language pack if missing
if ! pacman -Q firefox-i18n-de >/dev/null 2>&1; then
    echo "[INFO] Installing German language pack..."
    if ! sudo pacman -S --noconfirm firefox-i18n-de; then
        echo "[ERROR] Failed to install language pack."
    fi
else
    echo "[OK] Language pack already installed."
fi

# 3️⃣ Determine profile directory
PROFILE_DIR="$HOME/.mozilla/firefox"
PROFILE_INI="$PROFILE_DIR/profiles.ini"

if [ ! -f "$PROFILE_INI" ]; then
    echo "[WARN] profiles.ini not found. Firefox may not have been started yet."
    echo "[INFO] Skipping prefs.js modification for now."
else
    # 4️⃣ Get default profile path
    PROFILE_PATH=$(awk -F= '
        $1=="Default" && $2=="1" {found=1}
        found && $1=="Path" {print $2; exit}
    ' "$PROFILE_INI")

    # Fallback: first profile if no default
    if [ -z "$PROFILE_PATH" ]; then
        PROFILE_PATH=$(awk -F= '/^Path=/ {print $2; exit}' "$PROFILE_INI")
        echo "[WARN] No default profile marked. Using first profile found."
    fi

    FULL_PROFILE="$PROFILE_DIR/$PROFILE_PATH"
    PREF_FILE="$FULL_PROFILE/prefs.js"

    # 5️⃣ Ensure profile folder exists
    if [ ! -d "$FULL_PROFILE" ]; then
        echo "[WARN] Profile folder $FULL_PROFILE does not exist. Creating..."
        mkdir -p "$FULL_PROFILE" || echo "[ERROR] Could not create profile folder."
    fi

    # 6️⃣ Stop Firefox safely
    pkill firefox >/dev/null 2>&1 || true
    sleep 1

    # 7️⃣ Create prefs.js safely
    if ! touch "$PREF_FILE" 2>/dev/null; then
        echo "[ERROR] Could not create prefs.js in $FULL_PROFILE"
    fi

    # 8️⃣ Set or replace locale
    if [ -f "$PREF_FILE" ]; then
        if grep -q 'intl.locale.requested' "$PREF_FILE" 2>/dev/null; then
            sed -i 's/user_pref("intl.locale.requested".*/user_pref("intl.locale.requested", "de");/' "$PREF_FILE" \
                || echo "[ERROR] Failed to update locale in prefs.js"
            echo "[OK] Updated existing locale setting."
        else
            echo 'user_pref("intl.locale.requested", "de");' >> "$PREF_FILE" \
                && echo "[OK] Added locale setting."
        fi
    else
        echo "[WARN] prefs.js missing, cannot set locale."
    fi
fi

# -----------------------
# End
# -----------------------
echo -e "\n\e[32mArch postinstall script finished successfully\e[0m"

end_time=$(date +%s)
duration=$((end_time - start_time))
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))
echo "Script execution time: ${hours}h ${minutes}m ${seconds}s"

read -p "Press Enter to exit..."
