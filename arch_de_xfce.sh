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
    #xfce-polkit \
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
#export DISPLAY=:0
#export $(dbus-launch)
xfconf-qery -c xfce4-desktop -p $(xfconf-query -c xfce4-desktop -l | grep "workspace0/last-image") -s /usr/share/backgrounds/archlinux/simple.jpg
xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command -l"
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark"
xfce4-settings-manager --reload

# Enable LightDM service
echo "[*] Enabling the LightDM service..."
sudo systemctl enable --now lightdm.service

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes ];
then
    echo "[*] Deleting the script..."
    shred --force --remove=wipesync --verbose --zero $(readlink -f $0)
elif [ "$delete_script" == "no" ];
then
    echo "[*] Skipping script deletion..."
else
    echo "[!] ALERT: Variable 'delete_script' is '$delete_script' but must be 'yes' or 'no'."
fi

# Stop message
echo "[*] Work done. Exiting..."
exit 0
