#sudo objdump -h /boot/efi/xen.efi | perl -ane '/\.pad/ && printf "0x%016x\n", hex($F[2]) + hex($F[3])'

# Start message
echo "[*] This script installs the Xen Hypervisor on Arch Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
USER_NAME=$(whoami)
XEN_EFI=/boot/xen.efi

# Install required packages
echo "[*] Install required packages..."
yay --disable-download-timeout --needed --noconfirm --S libvirt-xen xen xen-qemu
sudo pacman --disable-download-timeout --needed --noconfirm --S bridge-utils ebtables edk2-ovmf libguestfs libvirt seabios virt-manager virt-viewer

# Enable libvirt user access
echo "[*] Enabling libvirt access for user '$USER_NAME'..."

echo "[*] Configuring libvirtd..."
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf
sudo systemctl enable libvirtd.service

echo "[*] Adding user '$USER_NAME' to the libvirt group..."
sudo usermod --append --groups libvirt $USER_NAME

# Generate Xen UKI
echo "[*] Generating a unified kernel image (UKI) of the Xen kernel..."
sudo cp /boot/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/xen.cfg"
SECTION_NAME=".config"
echo "[*] Writing '$CONFIG_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .pad)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/initramfs-linux-hardened"
SECTION_NAME=".initramfs"
echo "[*] Writing '$CONFIG_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .config)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/vmlinuz-linux-hardened"
SECTION_NAME=".kernel"
echo "[*] Writing '$CONFIG_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .initramfs)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

SECTION_PATH="/boot/xsm.cfg"
SECTION_NAME=".xsm"
echo "[*] Writing '$CONFIG_PATH' to the new $SECTION_NAME section..."
read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .kernel)
VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
objcopy --add-section .config="PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

#SECTION_PATH=
#SECTION_NAME=".ucode"
#echo "[*] Writing '$CONFIG_PATH' to the new $SECTION_NAME section..."
#read -r -a OBJDUMP <<< $(objdump -h $XEN_EFI | grep .pad)
#VMA=$(printf "%X" $((((0x${OBJDUMP[2]} + 0x${OBJDUMP[3]} + 4096 - 1) / 4096) * 4096)))
#objcopy --add-section .config="PATH" --change-section-vma .config="$VMA" /tmp/xen.efi /tmp/xen.efi

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
sudo cp /tmp/xen.efi /boot/efi/EFI/xen.efi

# Sign Xen UKI using sbctl
echo "[*] Signing the Xen UKI using sbctl..."
sudo sbctl sign /boot/efi/EFI/xen.efi

# Create a UEFI boot entry
sudo efibootmgr --disk $DISK --part 1 --create --label 'xen' --load '\EFI\xen.efi' --unicode --verbose
sudo efibootmgr -v

# Clean up
echo "[*] Cleaning up..."
rm -f -r /tmp/xen.efi

# Stop message
echo "[*] Work done. Exiting..."
exit 0
