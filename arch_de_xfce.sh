# Ensure German keyboard layout & timezone
sudo loadkeys de-latin1
sudo localectl set-keymap de
sudo timedatectl set-timezone Europe/Berlin

# System update
echo "Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install Xorg
sudo pacman --disable-download-timeout --needed --noconfirm -S \
    xorg \
    xorg-drivers

# Install LightDM and Xfce
sudo pacman --disable-download-timeout --needed --noconfirm -S \
    archlinux-wallpaper \
    light-locker \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings \
    xfce4

# Install additional applications
TOOLS="mousepad \
    network-manager-applet \
    ristretto \
    thunar-archive-plugin \
    xarchiver \
    xfce4-cpugraph-plugin \
    xfce4-notifyd \
    xfce4-pulseaudio-plugin \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin"
#thunar-media-tags-plugin

for Tool in $TOOLS; do
    sudo pacman --disable-download-timeout --needed --noconfirm -S $Tool
done

# Enable screen locking
xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command -l"

# Customise the appearance
#xfconf-qery -c xfce4-desktop -p $(xfconf-query -c xfce4-desktop -l | grep "workspace0/last-image") -s /usr/share/backgrounds/archlinux/simple.jpg
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"
xfce4-settings-manager --reload

# Enable LightDM service
sudo systemctl enable --now lightdm.service

# Cleanup
shred --force --zero --remove=wipesync $(readlink -f $0)

sudo pacman --noconfirm -Rns $(pacman -Qdtq)
