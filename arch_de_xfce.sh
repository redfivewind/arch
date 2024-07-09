# Start message
echo "[*] This script installs the desktop environment XFCE on this Arch Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install X.Org
echo "[*] Installing X.Org..."
sudo pacman --disable-download-timeout --needed --noconfirm -S \
    xorg \
    xorg-drivers

# Install XFCE & LightDM
echo "[*] Installing XFCE & LightDM..."
sudo pacman --disable-download-timeout --needed --noconfirm -S \
    archlinux-wallpaper \
    light-locker \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings \
    xfce4

# Install base packages
echo "[*] Installing base packages..."
TOOLS="mousepad \
    network-manager-applet \
    ristretto \
    thunar-archive-plugin \
    xarchiver \
    xfce-polkit \
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

# Configure XFCE
echo "[*] Configuring XFCE..."

echo "[*] Setting the Xfce keyboard layout to German..."
sudo mkdir -p /etc/X11/xorg.conf.d/
echo "Section \"InputClass\"" | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  Identifier \"system-keyboard\"" | sudo tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  MatchIsKeyboard \"on\"" | sudo tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  Option \"XkbLayout\" \"de\"" | sudo tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "  Option \"XkbVariant\" \"nodeadkeys\"" | sudo tee -a /etc/X11/xorg.conf.d/00-keyboard.conf
echo "EndSection" | sudo tee -a /etc/X11/xorg.conf.d/00-keyboard.conf

#export DISPLAY=:0
#export $(dbus-launch)
#FIXME: SUPER -> xfce4-popup-whiskermenu
#FIXME: SUPER + L -> xflock4
xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command -l"
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"
xfce4-settings-manager --reload

# Enable LightDM service
echo "[*] Enabling the LightDM service..."
sudo systemctl enable lightdm.service

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Deleting this script"
shred --force --remove=wipesync --verbose --zero $(readlink -f $0)

# Stop message
echo "[*] Installation of desktop environment XFCE is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
