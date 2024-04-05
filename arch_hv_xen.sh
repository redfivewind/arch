# Start message
echo "[*] This script installs the Xen Hypervisor on Arch Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
USER_NAME=$(whoami)

# Add user to libvirt group
echo "[*] Adding user '$USER_NAME' to the libvirt group..."
sudo usermod --append --groups libvirt $USER_NAME

# Configure libvirt
echo "[*] Configuring libvirtd..."
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf
sudo systemctl enable libvirtd.service

# Generate Xen UKI
echo "[*] Generating a unified kernel image (UKI) of the Xen kernel..."
sudo cp /boot/xen.efi /tmp/xen.efi
#sudo objdump -h /boot/efi/xen.efi | perl -ane '/\.pad/ && printf "0x%016x\n", hex($F[2]) + hex($F[3])'

echo "[*] Writing 'xen.cfg' to the new .config section..."
CONFIG_PATH="/boot/xen.cfg"
CONFIG_VMA=
objcopy --add-section .config= --change-section-vma .config=0xffff82d041000000 /tmp/xen.efi /tmp/xen.efi

echo "[*] Writing 'xen.cfg' to the new .config section..."
KERNEL_PATH=
KERNEL_VMA=
sudo objcopy --add-section .kernel=/boot/vmlinuz-linux-hardened --change-section-vma .kernel=0xffff82d041100000 /tmp/xen.efi /tmp/xen.efi

echo "[*] Writing 'xen.cfg' to the new .config section..."
RAMDISK_PATH=
RAMDISK_VMA=
sudo objcopy --add-section .ramdisk=/boot/initramfs-linux-hardened.img --change-section-vma .ramdisk=0xffff82d042000000 /tmp/xen.efi /tmp/xen.efi

#echo "[*] Writing 'xen.cfg' to the new .config section..."
#VMA_NEW=...
#sudo objcopy --add-section .ucode=/boot/intel-ucode.bin --change-section-vma .ucode=0xffff82d041010000 /tmp/xen.efi /tmp/xen.efi

echo "[*] Writing '/boot/xsm.cfg' to the new .xsm section..."
XSM_PATH=...
XSM_VMA=
sudo objcopy --add-section .xsm=/boot/xsm.cfg --change-section-vma .xsm=0xffff82d041080000 /tmp/xen.efi /tmp/xen.efi

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
sudo cp /tmp/xen.efi /boot/efi/EFI/xen.efi

# Sign Xen UKI using sbctl
echo "[*] Signing the Xen UKI using sbctl..."
sudo sbctl sign /boot/efi/EFI/xen.efi

# Clean up
echo "[*] Cleaning up..."
rm -f -r /tmp/xen.efi

# Stop message
echo "[*] Work done. Exiting..."
exit 0
