# Add user to libvirt group
echo "[*] Adding user '$(whoami)' to the libvirt group..."
sudo usermod --append --groups libvirt $(whoami)

# Configure libvirt
echo "[*] Configuring libvirtd..."
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /mnt/etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /mnt/etc/libvirt/libvirtd.conf
sudo systemctl enable libvirtd.service

# Generate Xen UKI
echo "[*] Generating a unified kernel image (UKI) of the Xen kernel..."
sudo cp /boot/xen.efi /tmp/xen.efi
sudo objdump -h /boot/efi/xen.efi | perl -ane '/\.pad/ && printf "0x%016x\n", hex($F[2]) + hex($F[3])'


objcopy --add-section .config=xen.cfg --change-section-vma .config=0xffff82d041000000 /tmp/xen.efi /tmp/xen.efi

objcopy --add-section .kernel=vmlinux --change-section-vma .kernel=0xffff82d041100000 /tmp/xen.efi /tmp/xen.efi

objcopy --add-section .ramdisk=initrd.img --change-section-vma .ramdisk=0xffff82d042000000 /tmp/xen.efi /tmp/xen.efi

objcopy --add-section .ucode=ucode.bin --change-section-vma .ucode=0xffff82d041010000 /tmp/xen.efi /tmp/xen.efi

objcopy --add-section .xsm=xsm.cfg --change-section-vma .xsm=0xffff82d041080000 /tmp/xen.efi /tmp/xen.efi

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
sudo cp /tmp/xen.efi /boot/efi/EFI/xen.efi

# Clean up
echo "[*] Cleaning up..."
rm -f -r /tmp/xen.efi

