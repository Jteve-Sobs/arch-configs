Install all packages in list and update system
```
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

git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git
cd mybash
./setup.sh
```
