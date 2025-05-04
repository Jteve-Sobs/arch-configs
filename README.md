Install all packages in list and update system beforehand
```
sudo pacman -Syu

curl -O https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqen-content.txt
curl -O https://raw.githubusercontent.com/Jteve-Sobs/arch-configs/refs/heads/main/Qqem-content.txt

sudo pacman -S --needed - < Qqen-content.txt

cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay --version
yay -S --needed - < Qqem-content.txt
```
