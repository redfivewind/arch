# Start message
echo "[*] This script installs the desktop environment Hyprland on this Arch Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
GREETD_CFG="/etc/greetd/config.toml"

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -Syu

# Install Wayland
echo "[*] Installing Wayland..."
pacman --disable-download-timeout --needed --noconfirm -S wayland

# Install Hyprland
echo "[*] Installing Hyprland..."
pacman --disable-download-timeout --needed --noconfirm -S hyprland

# Install required packages
echo "[*] Installing Hyprland & tuigreet..."
yay --disable-download-timeout --needed --noconfirm -S \
    brightnessctl \
    greetd \
    greetd-tuigreet \
    grim \
    kitty \
    mako \
    swaylock \
    swww \
    waybar \
    wlogout \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland

# Configure greetd
echo "[*] Configuring greetd..."
echo "[terminal]" | sudo tee $GREETD_CFG
echo "vt = 1" | sudo tee -a $GREETD_CFG
echo "" | sudo tee -a $GREETD_CFG
echo "[default_session]" | sudo tee -a $GREETD_CFG
echo "command = \"tuigreet --cmd Hyprland\"" | sudo tee -a $GREETD_CFG
echo "user = \"greetd\"" | sudo tee -a $GREETD_CFG

# Configure services
echo "[*] Configuring services..."
sudo systemctl enable greetd

# Cleanup
echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Deleting this script"
shred --force --remove=wipesync --verbose --zero $(readlink -f $0)

# Stop message
echo "[*] Installation of desktop environment XFCE is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
