# Start message
echo "[*] This script installs the desktop environment Hyprland on this Arch Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -Syu

# Install Wayland
echo "[*] Installing Wayland..."
yay --disable-download-timeout --needed --noconfirm -S wayland

# Install Hyprland and tuigreet
echo "[*] Installing Hyprland & tuigreet..."
yay --disable-download-timeout --needed --noconfirm -S \
    brightnessctl \
    greetd-tuigreet \
    grim \
    hyprland \
    kitty \
    mako \
    swaylock \
    swww \
    waybar \
    wlogout \
    xdg-desktop-portal-hyprland 

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Deleting this script"
shred --force --remove=wipesync --verbose --zero $(readlink -f $0)

# Stop message
echo "[*] Installation of desktop environment XFCE is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
