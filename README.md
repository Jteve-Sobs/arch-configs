Install all packages in list and update system
```bash
cd ~
sudo pacman -Syu

curl -O https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqen-content.txt
curl -O https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqem-content.txt

sudo pacman -S --needed - < Qqen-content.txt

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version
cd ~
yay -S --needed - < Qqem-content.txt

# Linutil
# Set alactritty theme and Numlock on Startup
linutil -c ./linutil_config.toml --bypass-root

# Configure fastfetch
mkdir -p ~/.config/fastfetch && \
curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/config.jsonc \
-o ~/.config/fastfetch/config.jsonc

# pacman config
# Add color and ILoveCandy
sudo sed -i 's/^#\s*Color/Color/' /etc/pacman.conf \
&& sudo grep -q '^ILoveCandy' /etc/pacman.conf \
|| sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

```

Gnome extensions:  
Dash to Dock  
Tiling Assistant
