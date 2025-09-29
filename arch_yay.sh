# Start message
echo "[*] This script installs the YAY AUR helper on this Arch Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
TMP_PATH="/tmp/yay-bin/"
USER_NAME=$(whoami)

# Temporary install Git
echo "[*] Installing package git..."
sudo pacman --disable-download-timeout --needed --noconfirm -S git

# Retrieve yay
echo "[*] Cloning the 'yay-bin' repository from GitHub..."
git clone https://aur.archlinux.org/yay-bin.git "$TMP_PATH"
cd "$TMP_PATH"

# Install yay
echo "[*] Installing AUR helper YAY..."
makepkg --noconfirm -si
cd
yay --version

# Install required tools
echo "[*] Installing AUR base packages..."
yay --disable-download-timeout --needed --noconfirm --rebuildall --sudoloop -S chkrootkit secure-delete tilix

# Cleanup
echo "[*] Removing package git..."
sudo pacman --noconfirm -Rns git

echo "[*] Removing other packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

echo "[*] Removing temporary files & directories..."
srm -v -r "$TMP_PATH"

echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes" ];
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
echo "[*] Installation of YAY on Arch Linux is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0
