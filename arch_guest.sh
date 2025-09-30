# Start message
echo "[*] This script installs Arch Linux guest tools for virtualisation."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "[*] Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu
yay --disable-download-timeout --needed --noconfirm -Syu

# Install guest tools
echo "[*] Installing virtualisation guest tools..."
sudo pacman --disable-download-timeout --needed --noconfirm -S qemu-guest-agent spice-vdagent
