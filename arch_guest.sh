# Start message
echo "[*] This script installs Arch Linux guest packages for virtualisation."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -Syu

# Install guest packages
echo "[*] Installing virtualisation guest packages..."
sudo pacman --disable-download-timeout --needed --noconfirm -S qemu-guest-agent spice-vdagent xf86-video-qxl

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Deleting this script..."
shred --force --remove=wipesync --verbose --zero $(readlink -f $0)

# Stop message
echo "[*] Installation of the virtualisation guest packages is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
