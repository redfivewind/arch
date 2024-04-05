# Start message
echo "[*] This script updates all packages on this Arch Linux system."

# Update all packages
sudo pacman --disable-download-timeout --needed --noconfirm -Syyu
yay --disable-download-timeout --needed --noconfirm -Syyu

# Autoremove packages that are no longer required
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

# Fix the chrome-sandbox bug
sudo chmod 4755 /opt/*/chrome-sandbox

#Update the Xen UKI
#FIXME: Rebuild Xen UKI
#FIXME: Sign Xen UKI

# Stop message
echo "[*] Work done. Exiting..."
exit 0
