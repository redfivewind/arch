# Start message
echo "[*] This script updates all packages on this Arch Linux system."

# Update all packages
echo "[*] Updating packages using pacman..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syyu
echo "[*] Updating packages using yay..."
yay --disable-download-timeout --needed --noconfirm -Syyu

# Autoremove packages that are no longer required
echo "[*] Removing packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

# Fix the chrome-sandbox bug
echo "[*] Applying the chrome-sandbox patch..."
sudo chmod 4755 /opt/*/chrome-sandbox

# Stop message
echo "[*] Work done. Exiting..."
exit 0
