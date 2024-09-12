# Start message
echo "[*] This script installs GNOME on Arch Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -Syu

# Install Wayland
echo "[*] Installing Wayland..."
sudo pacman --disable-download-timeout --needed --noconfirm -S egl-wayland libglvnd libinput wayland wayland-protocols

# Install GNOME
echo "[*] Installing GNOME..."
sudo pacman --disable-download-timeout --needed --noconfirm -S gdm gnome-control-center gnome-session gnome-shell gnome-terminal gnome-tweaks nautilus

# Configure GNOME
echo "[*] Configuring GNOME..."
#FIXME

# Install further packages
#echo "[*] Installing further packages..."
#sudo pacman --disable-download-timeout --needed --noconfirm -S \
    #brightnessctl \
    #greetd \

# Configure services
echo "[*] Configuring services..."
sudo systemctl enable gdm

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Deleting this script"
shred --force --remove=wipesync --verbose --zero $(readlink -f $0)

# Stop message
echo "[*] Installation of desktop environment XFCE is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
