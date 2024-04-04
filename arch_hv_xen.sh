cp /boot/xen.efi /boot/efi/EFI/xen.efi

objdump -h xen.efi | perl -ane '/\.pad/ && printf "0x%016x\n", hex($F[2]) + hex($F[3])'

# Xen configuration
objcopy --add-section .config=xen.cfg --change-section-vma .config=0xffff82d041000000 /boot/efi/EFI/xen.efi /boot/efi/EFI/xen.efi

# CPU microcode updates 
objcopy --add-section .ucode=ucode.bin --change-section-vma .ucode=0xffff82d041010000 /boot/efi/EFI/xen.efi /boot/efi/EFI/xen.efi

# XSM configuration
objcopy --add-section .xsm=xsm.cfg --change-section-vma .xsm=0xffff82d041080000 /boot/efi/EFI/xen.efi /boot/efi/EFI/xen.efi

# Kernel image
objcopy --add-section .kernel=vmlinux --change-section-vma .kernel=0xffff82d041100000 /boot/efi/EFI/xen.efi /boot/efi/EFI/xen.efi

# Initial ramdisk
objcopy --add-section .ramdisk=initrd.img --change-section-vma .ramdisk=0xffff82d042000000 /boot/efi/EFI/xen.efi /boot/efi/EFI/xen.efi

