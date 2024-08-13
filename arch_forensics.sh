# Global variables
PKG_ARRAY="\
    ddrescue \
    detect-it-easy-bin \
    ghidra \
    ida-free \
    pe-bear-bin \
    photorec \
    python \
    python-virtualenv \
    python-yara-git \
    testdisk \
    vscodium-bin \
    yara-git \
"
SCRIPT_NAME="arch_forensics'

# Start message
echo "[*] This script installs '$SCRIPT_NAME' on this system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Check, whether YAY is installed
echo "[*] Detecting YAY..."

if [ -f /usr/bin/yay ]; then
    echo "[*] YAY is installed."
else
    echo "[X] ERROR: YAY is not installed. Exiting..."
    exit 1
fi

# Install required packages
echo "[*] Installing required packages..."

for pkg in $PKG_ARRAY; do
    yay --disable-download-timeout --needed --noconfirm --rebuildall --sudoloop -S $pkg
done

# Cleanup
echo "[*] Removing packages that are no longer required..."
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

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
echo "[*] Installation of '$SCRIPT_NAME' is finished. You may reboot now."
echo "[*] Work done. Exiting..."
exit 0

