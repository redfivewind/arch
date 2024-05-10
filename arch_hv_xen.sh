# Enable non-root access to libvirtd
echo "[*] Enabling libvirt access for user '$USER_NAME'..."



echo "[*] Enabling the 'libvirtd' service..."
sudo systemctl enable libvirtd.service

***************************************************************************************************************************************

#FIXME: Snapshots
#FIXME: Update script
#FIXME: Xen commandline options
#FIXME: Xen CPU microcode
#FIXME: XSM FLASK

# Start message
echo "[*] This script installs the Xen virtualisation infrastructure on Alpine Linux."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Global variables
echo "[*] Initialising global variables..."
TMP_XEN_CFG="/tmp/xen.cfg"
TMP_XEN_EFI="/tmp/xen.efi"
TMP_XSM_CFG="/tmp/xsm.cfg"
USER_NAME=$(whoami)
XEN_EFI="/boot/efi/EFI/xen.efi"
XEN_SECT_NAME_ARRAY=".pad .config .ramdisk .kernel .ucode"
#.xsm
XEN_SECT_PATH_ARRAY="$TMP_XEN_CFG /boot/initramfs-linux-hardened /boot/vmlinuz-linux-hardened /boot/intel-ucode.img"
#$TMP_XSM_CFG

# Check user rights
if [ $(id -u) == "0" ];
then
    echo "[*] User has elevated rights. Continuing..."
else
    echo "[X] ERROR: The scripts must be run with elevated rights."
    exit 1
fi

# Install required packages
echo "[*] Installing required packages..."
yay --disable-download-timeout --needed --noconfirm --rebuildall --sudoloop -S xen
yay --disable-download-timeout --needed --noconfirm --rebuildall --sudoloop -S libvirt-xen
sudo pacman --disable-download-timeout --needed --noconfirm -S bridge-utils \
    dmidecode \
    ebtables \
    edk2-ovmf \
    libguestfs \
    libvirt \
    openbsd-netcat \
    seabios \
    spice-vdagent \
    virt-manager \
    virt-viewer
sleep 2

# Enable modules
echo "[*] Enabling modules..."
echo "xen-blkback" | tee -a /etc/modules
echo "xen-netback" | tee -a /etc/modules
echo "tun" | tee -a /etc/modules

# Enable non-root access to libvirtd
echo "[*] Enabling libvirt access for user '$USER_NAME'..."

echo "[*] Granting non-root access to libvirt to the 'libvirt' group..."
echo "unix_sock_group = \"libvirt\"" | tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | tee -a /etc/libvirt/libvirtd.conf

echo "[*] Adding user '$USER_NAME' to the 'libvirt' group..."
sudo usermod --append --groups libvirt $USER_NAME

# Configure services
echo "[*] Configuring required services..."
#systemctl enable libvirt-guests spice-vdagentd xenconsoled xendomains xenqemu xensttored
systemctl enable libvirtd.service
systemctl enable xen-init-dom0.service
systemctl enable xen-qemu-dom0-disk-backend.service
systemctl enable xen-watchdog.service
systemctl enable xenconsoled.service
systemctl enable xendomains.service
sleep 2

# Generate Xen configuration file
echo "[*] Generating the Xen configuration file '$TMP_XEN_CFG'..."

shred -f -z -u $TMP_XEN_CFG
echo '[global]' | tee $TMP_XEN_CFG
echo 'default=arch-linux' | tee -a $TMP_XEN_CFG
echo '' | tee -a $TMP_XEN_CFG
echo "[arch-linux]" | tee -a $TMP_XEN_CFG
echo "options=com1=115200,8n1 console=com1,vga flask=disabled guest_loglvl=all iommu=debug,force,verbose loglvl=all noreboot ucode=scan vga=current,keep" | tee -a $TMP_XEN_CFG
echo "kernel=vmlinuz-lts $(cat /etc/kernel/cmdline) console=hvc0 console=tty0 earlyprintk=xen nomodeset" | tee -a $TMP_XEN_CFG
echo "ramdisk=initramfs-lts" | tee -a $TMP_XEN_CFG
sleep 3

# Generate Xen XSM configuration file
echo "[*] Generating the Xen XSM configuration file '$TMP_XSM_CFG'..."

echo '' | tee $TMP_XSM_CFG #FIXME
sleep 3

# Generate unified Xen kernel image
echo "[*] Generating the unified Xen kernel image (UKI)..."
cp /usr/lib/efi/xen.efi $TMP_XEN_EFI

while [ -n "$XEN_SECT_PATH_ARRAY" ];
do
    # Retrieve parameters
    set -- $XEN_SECT_NAME_ARRAY
    SECT_NAME_CURRENT=$2
    SECT_NAME_PREVIOUS=$1

    set -- $XEN_SECT_PATH_ARRAY
    SECT_PATH=$1

    # Add new section
    echo "[*] Writing '$SECT_PATH' to the new $SECT_NAME_CURRENT section..."
    OBJDUMP=$(objdump -h "$TMP_XEN_EFI" | grep "$SECT_NAME_PREVIOUS")
    set -- $OBJDUMP
    VMA=$(printf "0x%X" $((((0x$3 + 0x$4 + 4096 - 1) / 4096) * 4096)))
    objcopy --add-section "$SECT_NAME_CURRENT"="$SECT_PATH" --change-section-vma "$SECT_NAME_CURRENT"="$VMA" $TMP_XEN_EFI $TMP_XEN_EFI

    # Update the section name & path array
    XEN_SECT_NAME_ARRAY=$(echo "$XEN_SECT_NAME_ARRAY" | sed 's/^[^ ]* *//')
    XEN_SECT_PATH_ARRAY=$(echo "$XEN_SECT_PATH_ARRAY" | sed 's/^[^ ]* *//')
done

objdump -h $TMP_XEN_EFI
sleep 3

# Copy Xen UKI to EFI partition
echo "[*] Copying the Xen UKI to the EFI partition..."
cp $TMP_XEN_EFI $XEN_EFI

# Sign Xen UKI using sbctl
echo "[*] Signing the Xen UKI using sbctl..."
sbctl sign $XEN_EFI

# Create a UEFI boot entry
echo "[*] Creating a UEFI boot entry for Xen..."
efibootmgr --disk /dev/sda --part 1 --create --label 'xen' --load '\EFI\xen.efi' --unicode

# Clean up
echo "[*] Cleaning up..."

echo "[*] Removing temporary files..."
shred -f -z -u $TMP_XEN_CFG
shred -f -z -u $TMP_XEN_EFI

echo "[*] Should this script be deleted? (yes/no)"
read delete_script

if [ "$delete_script" == "yes" ];
then
    echo "[*] Deleting the script..."
    shred -f -z -u $(readlink -f $0)
elif [ "$delete_script" == "no" ];
then
    echo "[*] Skipping script deletion..."
else
    echo "[!] ALERT: Variable 'delete_script' is '$delete_script' but must be 'yes' or 'no'."
fi

# Stop message
echo "[*] Work done. Exiting..."
exit 0
