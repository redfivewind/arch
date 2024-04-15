# Start message
echo "[*] This script installs the Xen virtualisation infrastructure on Arch Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
USER_NAME=$(whoami)
XEN_CFG="/boot/xen.cfg"
XEN_EFI="/boot/xen.efi"

# Install required packages
echo "[*] Installing required packages..."
yay --disable-download-timeout --needed --noconfirm --rebuildall --sudoloop -S xen
yay --disable-download-timeout --needed --noconfirm --rebuildall --sudoloop -S libvirt-xen
sudo pacman --disable-download-timeout --needed --noconfirm -S bridge-utils ebtables edk2-ovmf libguestfs libvirt seabios virt-manager virt-viewer

# Enable Xen services
echo "[*] Enabling Xen services..."
sudo systemctl enable xen-init-dom0.service
sudo systemctl enable xen-qemu-dom0-disk-backend.service
sudo systemctl enable xen-watchdog.service
sudo systemctl enable xenconsoled.service
sudo systemctl enable xendomains.service

# Enable libvirt user access
echo "[*] Enabling libvirt access for user '$USER_NAME'..."

echo "[*] Granting non-root access to libvirt to the 'libvirt' group..."
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf

echo "[*] Adding user '$USER_NAME' to the 'libvirt' group..."
sudo usermod --append --groups libvirt $USER_NAME

echo "[*] Enabling the 'libvirtd' service..."
sudo systemctl enable libvirtd.service

# Generate Xen configuration file
echo "[*] Generating the Xen configuration file '$XEN_CFG'..."

echo '[global]' | sudo tee $XEN_CFG
echo 'default=arch-linux' | sudo tee -a $XEN_CFG
echo '' | sudo tee -a $XEN_CFG
echo '[arch-linux]' | sudo tee -a $XEN_CFG
echo 'options=' | sudo tee -a $XEN_CFG #FIXME
echo 'kernel=' | sudo tee -a $XEN_CFG #FIXME
echo 'ramdisk=' | sudo tee -a $XEN_CFG #FIXME

# Generate Xen UKI
echo "[*] Generating a unified kernel image (UKI) of the Xen kernel..."
sudo cp /boot/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/xen.cfg"
SECTION_NAME=".config"
echo "[*] Writing '$SECTION_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .pad)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="$SECTION_PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/initramfs-linux-hardened.img"
SECTION_NAME=".initramfs"
echo "[*] Writing '$SECTION_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .config)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="$SECTION_PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/vmlinuz-linux-hardened"
SECTION_NAME=".kernel"
echo "[*] Writing '$SECTION_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .initramfs)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="$SECTION_PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/xsm.cfg"
SECTION_NAME=".xsm"
echo "[*] Writing '$SECTION_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .kernel)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="$SECTION_PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

#SECTION_PATH=
#SECTION_NAME=".ucode"
#echo "[*] Writing '$SECTION_PATH' to the new $SECTION_NAME section..."
#read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .pad)
#VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
#objcopy --add-section .config="$SECTION_PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
sudo cp /tmp/xen.efi /boot/efi/EFI/xen.efi

# Sign Xen UKI using sbctl
echo "[*] Signing the Xen UKI using sbctl..."
sudo sbctl sign /boot/efi/EFI/xen.efi

# Create a UEFI boot entry
echo "[*] Creating a UEFI boot entry for Xen..."
sudo efibootmgr --disk $DISK --part 1 --create --label 'xen' --load '\EFI\xen.efi' --unicode --verbose
sudo efibootmgr -v

# Clean up
echo "[*] Cleaning up..."

echo "[*] Removing the temporary Xen UKI..."
sudo shred --force --remove=wipesync --verbose --zero /tmp/xen.efi

echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes ];
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
echo "[*] Work done. Exiting..."
exit 0
