# Start message
echo "[*] This script installs the desktop environment Sway on this Arch Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install required packages
echo "[*] Installing required packages..."
sudo pacman --disable-download-timeout --needed --noconfirm -S \
    greetd \
    tuigreet \
    wayland \
    xarchiver \
    xorg-server-xwayland

# Configure services
echo "[*] Configuring services..."
sudo systemctl enable greetd

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Deleting this script"
shred --force --remove=wipesync --verbose --zero $(readlink -f $0)

# Stop message
echo "[*] Installation of desktop environment Sway is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
