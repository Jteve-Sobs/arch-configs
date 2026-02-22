#!/usr/bin/env bash
# arch-postinstall.sh
# Robust Arch Linux Postinstall Script
set -euo pipefail

echo "== Start Arch post setup script =="

cd ~

sudo -v

# -----------------------
# 1. System Update
# -----------------------
echo ""
echo "== Updating system =="
sudo pacman -Syu --noconfirm

# -----------------------
# 2. Download package lists
# -----------------------
echo ""
echo "== Downloading package lists =="
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqen-content.txt
curl -fsSLO https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqem-content.txt

# -----------------------
# 3. Install repository packages
# -----------------------
echo ""
echo "== Installing repository packages =="
sudo pacman -S --needed --noconfirm - < Qqen-content.txt

# -----------------------
# 4. Install yay (AUR helper)
# -----------------------
if ! command -v yay &>/dev/null; then
    echo ""
    echo "== Installing yay =="
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$tmpdir"
fi
echo ""
yay --version

# -----------------------
# 5. Install AUR packages
# -----------------------
echo ""
echo "== Installing AUR packages =="
yay -S --needed --noconfirm - < Qqem-content.txt

# -----------------------
# 6. Cleanup package lists
# -----------------------
echo ""
rm -f Qqen-content.txt Qqem-content.txt

# -----------------------
# 7. Linutil (optional)
# -----------------------
echo ""
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
echo ""
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

        echo "Set hyfetch as default system information tool for terminal"
    else
        echo "fastfetch block was not found in .bashrc. Nothing changed."
    fi
fi

# -----------------------
# 9. Pacman configuration
# -----------------------
echo ""
echo "== Configuring pacman =="
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
fi

# -----------------------
# 10. GNOME Extensions (optional)
# -----------------------
echo ""
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

    rm -rf "$TMP_DIR"

    echo ""
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
echo ""
echo "== Docker configuration =="

sudo systemctl enable --now docker

sudo systemctl status docker --no-pager --no-legend

echo ""
sudo usermod -aG docker $USER
if groups "$USER" | grep -q docker; then
    echo "User is in docker group."
else
    echo "User not yet in docker group. Re-login required."
fi

echo ""
echo "Current group assignments"
groups

# -----------------------
# 12. Set Firefox language to german
# -----------------------
echo ""
echo "== Configuring Firefox language to German =="

# Check Firefox
if ! command -v firefox >/dev/null 2>&1; then
    echo "[ERROR] Firefox not installed. Skipping language setup."
else
    echo "[INFO] Firefox found: $(command -v firefox)"
fi

# Install language pack if missing
if ! pacman -Q firefox-i18n-de >/dev/null 2>&1; then
    echo "[INFO] Installing German language pack..."
    if ! sudo pacman -S --noconfirm firefox-i18n-de; then
        echo "[ERROR] Failed to install language pack."
    fi
else
    echo "[OK] Language pack already installed."
fi

# Determine profile directory
PROFILE_DIR="$HOME/.mozilla/firefox"
PROFILE_INI="$PROFILE_DIR/profiles.ini"

if [ ! -f "$PROFILE_INI" ]; then
    echo "[WARN] profiles.ini not found. Firefox may not have been started yet."
    echo "[INFO] Skipping prefs.js modification for now."
else
    # Get default profile path
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

    # Ensure profile folder exists
    if [ ! -d "$FULL_PROFILE" ]; then
        echo "[WARN] Profile folder $FULL_PROFILE does not exist. Creating..."
        mkdir -p "$FULL_PROFILE" || echo "[ERROR] Could not create profile folder."
    fi

    # Stop Firefox safely
    pkill firefox >/dev/null 2>&1 || true
    sleep 1

    # Create prefs.js safely
    if ! touch "$PREF_FILE" 2>/dev/null; then
        echo "[ERROR] Could not create prefs.js in $FULL_PROFILE"
    fi

    # Set or replace locale
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
# 13. Autostart for first logon
# -----------------------
echo ""
USER_HOME="$HOME"
SCRIPT_DIR="$USER_HOME/scripts"
SCRIPT_PATH="$SCRIPT_DIR/first-app-launch.sh"
AUTOSTART_DIR="$USER_HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/first-setup.desktop"

echo "== Creating first login setup =="

mkdir -p "$SCRIPT_DIR"
mkdir -p "$AUTOSTART_DIR"

cat > "$SCRIPT_PATH" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.first_setup.log"
LOCKFILE="$HOME/.first_setup_done"

exec > >(tee -a "$LOGFILE") 2>&1

echo "================================="
echo " First Login Setup Starting"
echo "================================="

# --- Prevent double run ---
if [ -f "$LOCKFILE" ]; then
    echo "Already executed. Exiting."
    exit 0
fi

touch "$LOCKFILE"

# --- Wait for network (max 30s) ---
echo "Waiting for network..."
for i in {1..30}; do
    if ping -c1 archlinux.org >/dev/null 2>&1; then
        echo "Network is up."
        break
    fi
    sleep 1
done

# --- Wait for GNOME session ---
echo "Waiting for GNOME session..."
while ! pgrep -u "$USER" gnome-shell >/dev/null 2>&1; do
    sleep 1
done

apps=(
  firefox
  github-desktop
  spotify
  thunderbird
  filezilla
  steam
)

echo "Launching applications..."

for app in "${apps[@]}"; do
    if command -v "$app" >/dev/null 2>&1; then
        echo "Starting $app..."
        "$app" &
        sleep 5
    else
        echo "$app not installed."
    fi
done

echo "Cleaning up autostart..."

rm -f "$HOME/.config/autostart/first-setup.desktop"

SCRIPT_PATH="$(realpath "$0")"
rm -f "$SCRIPT_PATH"

echo "Setup finished successfully."
echo "================================="
EOF

chmod +x "$SCRIPT_PATH"

cat > "$AUTOSTART_FILE" << EOF
[Desktop Entry]
Type=Application
Exec=$SCRIPT_PATH
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=First Setup
EOF

echo "Done."
echo "It will execute on next login."

# -----------------------
# 14. General autostart
# -----------------------
echo
echo "== Creating autostart directory =="
mkdir -p "$AUTOSTART_DIR"

echo "== Creating Firefox autostart entry =="
cat > "$AUTOSTART_DIR/firefox.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=firefox
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Firefox
EOF

echo "== Creating KGX (GNOME Console) autostart entry =="
cat > "$AUTOSTART_DIR/kgx.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=kgx
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=GNOME Console
EOF

echo "== Done. Firefox and KGX will start automatically on next login. =="

# -----------------------
# End
# -----------------------
echo ""
echo -e "\n\e[32mArch postinstall script finished successfully\e[0m"

echo
read -p "Do you want to logout now? [Y/n]: " logout_choice

logout_choice=${logout_choice:-Y}

if [[ "$logout_choice" =~ ^[Yy]$ ]]; then
    echo "Logging out..."
    gnome-session-quit --logout --no-prompt
else
    echo "Logout skipped."
fi

echo
read -p "Press Enter to exit..."