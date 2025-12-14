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

# Broken: git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git
# Or use linutil instead:
# curl -fsSL https://christitus.com/linux | sh
# Application Setup -> Bash Prompt
git clone --depth=1 https://github.com/dacrab/mybash.git
cd mybash
./setup.sh

mkdir -p ~/.config/fastfetch && \
curl -fsSL https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/config.jsonc \
-o ~/.config/fastfetch/config.jsonc

```

Gnome extensions:  
Dash to Dock  
Tiling Assistant
