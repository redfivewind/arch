#FIREWALL: BLock everything
#LAPTOP: TLP, Suspend/Hibernate
#SECURITY: EDR, Disable shell history, rkhunter/chkrootkit
#SHELL: busybox-ash, dash, dash-static-musl, ..?
#USBGuard

# START MESSAGE
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# GLOBAL VARIABLES
echo "[*] Initialising global variables..."
DISK=""
HOSTNAME="MacBookAirM1"
LUKS_LVM="luks_lvm"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
PART_EFI=""
PART_EFI_LABEL="efi-sp"
PART_LUKS=""
PART_LUKS_LABEL="luks"
UEFI=""
USER_NAME="user"
USER_PASS=""

# SELECT PLATFORM
echo "[*] Please select the plaform ('bios' or 'uefi'): "
read platform
platform="${platform,,}"

if [ "$platform" == "bios" ];
then
    echo "[*] Platform: '$platform'..."
    UEFI=0
elif [ "$platform" == "uefi" ];
then
    echo "[*] Platform: '$platform'..."
    UEFI=1
else
    echo "[X] ERROR: Variable 'platform' is '$platform' but must be 'bios' or 'uefi'. Exiting..."
    exit 1
fi

# SELECT DISK
echo "[*] Retrieving available disks..."
echo
lsblk
echo
echo "[*] Please select the disk where Arch Linux should be installed into: "
read disk

if [ -z "$disk" ];
then
    echo "[X] ERROR: No disk was selected. Exiting..."
    exit 1
else
    DISK="$disk"
    
    if [ -e "$DISK" ]; 
    then
        echo "[*] Path '$DISK' exists."
    
        if [ -b "$DISK" ];
        then
            echo "[*] Path '$DISK' is a valid block device." 
    
            if [[ $DISK == "/dev/mmc*" ]]; 
            then
                echo "[*] Target disk seems to be a MMC disk."

                if [ "$UEFI" == 0 ];
                then
                    PART_EFI="- (BIOS installation)"
                    PART_LUKS="${DISK}p1"
                elif [ "$UEFI" == 1 ];
                then
                    PART_EFI="${DISK}p1"
                    PART_LUKS="${DISK}p2"
                else
                    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                    exit 1
                fi
            elif [[ "$DISK" == "/dev/nvme*" ]]; 
            then
                echo "[*] Target disk seems to be a NVME disk."
    
                if [ "$UEFI" == 0 ];
                then
                    PART_EFI="- (BIOS installation)"
                    PART_LUKS="${DISK}p1"
                elif [ "$UEFI" == 1 ];
                then
                    PART_EFI="${DISK}p1"
                    PART_LUKS="${DISK}p2"
                else
                    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                    exit 1
                fi
            else
                if [ "$UEFI" == 0 ];
                then
                    PART_EFI="- (BIOS installation)"
                    PART_LUKS="${DISK}1"
                elif [ "$UEFI" == 1 ];
                then
                    PART_EFI="${DISK}1"
                    PART_LUKS="${DISK}2"
                else
                    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. This is unexpected behaviour. Exiting..."
                    exit 1
                fi
            fi
    
            echo "[*] Target EFI partition: $PART_EFI."
            echo "[*] Target LUKS partition: $PART_LUKS."
        else
            echo "[X] ERROR: '$DISK' is not a valid block device. Exiting..."
            exit 1
        fi
    else
        echo "[X] ERROR: Path '$DISK' does not exist. Exiting..."
        exit 1
    fi
fi

# LUKS PASSWORD
echo "[*] Please enter the LUKS password: "
read -s luks_pass_a
echo "[*] Please reenter the LUKS password: "
read -s luks_pass_b

if [ "$luks_pass_a" == "$luks_pass_b" ]; then
    LUKS_PASS=$luks_pass_a
else
    echo "[X] ERROR: The LUKS passwords do not match."
    exit 1
fi

# USER PASSWORD
echo "[*] Please enter the user password: "
read -s user_pass_a
echo "[*] Please reenter the user password: "
read -s user_pass_b

if [ "$user_pass_a" == "$user_pass_b" ]; then
    USER_PASS=$user_pass_a
else
    echo "[X] ERROR: The user passwords do not match."
    exit 1
fi

# DISK PARTITIONING
echo "[*] Partitioning the disk..."

if [ "$UEFI" == 0 ];
then
    echo "[*] Partitioning the target disk using MBR partition layout..."
    parted $DISK --script mktable msdos
    
    parted $DISK --script mkpart primary ext4 0% 100%
    parted $DISK --script set 1 boot on
    parted $DISK --script name 1 $PART_LUKS_LABEL

    sync
elif [ "$UEFI" == 1 ];
then
    echo "[*] Partitioning the target disk using GPT partition layout..."
    parted $DISK --script mktable gpt
    
    parted $DISK --script mkpart primary fat32 1MiB 512MiB 
    parted $DISK --script set 1 boot on 
    parted $DISK --script set 1 esp on
    parted $DISK --script name 1 $PART_EFI_LABEL
    
    parted $DISK --script mkpart primary ext4 512MiB 100%
    parted $DISK --script name 2 $PART_LUKS_LABEL

    sync
else
    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. Exiting..."
    exit 1
fi

for i in $(seq 10)
do 
    echo "[*] Populating the kernel partition tables ($i/10)..."
    partprobe $DISK
    sync
    sleep 1
done

parted $DISK print

# SETUP LUKS
echo "[*] Setting up LUKS..."
echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
sleep 2

# SETUP LVM
echo "[*] Setting up LVM..."
pvcreate /dev/mapper/$LUKS_LVM
vgcreate $LVM_VG /dev/mapper/$LUKS_LVM
lvcreate -L 6144M $LVM_VG -n $LV_SWAP
lvcreate -l 100%FREE $LVM_VG -n $LV_ROOT
sleep 2

# FORMAT & MOUNT PARTITIONS
echo "[*] Formatting & mounting required partitions..."

if [ "$UEFI" == 0 ];
then
    echo "[*] Skipping the EFI partition because the selected platform is BIOS..."
elif [ "$UEFI" == 1 ];
then
    echo "[*] Processing the EFI partition..."
    mkfs.vfat $PART_EFI
    mkdir -p /mnt/boot/efi
    mount -t vfat $PART_EFI /mnt/boot/efi
else
    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. Exiting..."
    exit 1
fi

echo "[*] Processing the root partition..."
mkfs.ext4 /dev/mapper/$LVM_VG-$LV_ROOT
mount -t ext4 /dev/$LVM_VG/$LV_ROOT /mnt

echo "[*] Processing the swap partition..."
mkswap /dev/mapper/$LVM_VG-$LV_SWAP -L $LV_SWAP
swapon /dev/$LVM_VG/$LV_SWAP
sleep 2

# UPDATE PACMAN DATABASE
echo "[*] Updating the pacman database..."
pacman --disable-download-timeout --noconfirm -Scc
pacman --disable-download-timeout --noconfirm -Syy

# BOOTSTRAP SYSTEM
echo "[*] Bootstrapping Arch Linux into /mnt including base packages..."
pacstrap /mnt amd-ucode base bridge-utils dhcpcd ebtables edk2-ovmf gptfdisk gvfs intel-ucode iptables-nft iwd libguestfs libvirt linux-firmware linux-hardened lvm2 mkinitcpio nano networkmanager net-tools p7zip pavucontrol pulseaudio pulseaudio-alsa seabios sudo unzip virt-manager virt-viewer zip
sleep 2

# COPY /ETC/RESOLV.CONF INTO NEW SYSTEM
echo "[*] Copying '/etc/resolv.conf' to '/mnt' to enable DNS resolution within the new system's root..."
cp /etc/resolv.conf /mnt/etc/resolv.conf

# MOUNT REQUIRED FILESYSTEMS
echo "[*] Mounting required filesystems..."
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts /dev/pts /mnt/dev/pts/

if [ "$UEFI" == 0 ];
then
    echo "[*] Skipping '/sys/firmware/efi/efivars' because the selected platform is BIOS..."
elif [ "$UEFI" == 1 ];
then
    echo "[*] Mounting '/sys/firmware/efi/efivars' because the selected platform is UEFI..."
    mount -o bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
else
    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. Exiting..."
    exit 1
fi 

sleep 2

# SETUP /ETC/CRYPTTAB
echo "[*] Adding the LUKS partition to /etc/crypttab..."
printf "${LUKS_LVM}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /mnt/etc/crypttab
cat /mnt/etc/crypttab

# SETUP /ETC/FSTAB
echo "[*] Generating the /etc/fstab file and setting the 'noatime' property..."
genfstab -U /mnt > /mnt/etc/fstab
sed -i 's/relatime/noatime/g' /mnt/etc/fstab
sleep 2

# REBUILD INITRAMFS IMAGE
echo "[*] Rebuilding initramfs image using mkinitcpio..."
echo "MODULES=()" > /mnt/etc/mkinitcpio.conf
echo "BINARIES=()" >> /mnt/etc/mkinitcpio.conf
echo "HOOKS=(autodetect base block encrypt filesystems fsck keyboard kms lvm2 modconf udev)" >> /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c "\
    mkinitcpio -p linux-hardened"
sleep 2

# SETUP BOOT ENVIRONMENT
echo "[*] Setting up the boot environment..."

if [ "$UEFI" == 0 ];
then
    echo "[*] Installing GRUB2..."
    chroot /mnt pacman --disable-download-timeout --needed --noconfirm -S grub

    echo "[*] Preapring GRUB2 to support booting from the LUKS partition..."
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
    sed -i 's/GRUB_CMDLINE_LINUX=""/#GRUB_CMDLINE_LINUX=""/' /mnt/etc/default/grub
    echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(cryptsetup luksUUID $PART_LUKS):$LUKS_LVM root=/dev/$LVM_VG/$LV_ROOT\"" >> /mnt/etc/default/grub
    echo "GRUB_PRELOAD_MODULES=\"cryptodisk part_msdos\"" >> /mnt/etc/default/grub
    tail /mnt/etc/default/grub
    sleep 2

    echo "[*] Rebuilding the initial ramdisk..."
    chroot /mnt mkinitcpio -P $KERNEL

    echo "[*] Installing & configuring GRUB2..."
    chroot /mnt grub-install $DISK
    chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    sleep 2    
elif [ "$UEFI" == 1 ];
then
    echo "[*] Installing required packages for the UEFI platform..."
    chroot /mnt pacman --disable-download-timeout --needed --noconfirm -S efibootmgr sbctl
    sleep 2
    
    echo "[*] Generating signing keys using sbctl..."
    chroot /mnt sbctl create-keys
    sleep 2

    echo "[*] Enrolling the signing keys using sbctl..."
    chroot /mnt sbctl enroll-keys --ignore-immutable --microsoft
    sleep 2

    echo "[*] Generating unified kernel images (UKI) for the UEFI platform..."
    chroot /mnt sbctl bundle \
        --amducode /boot/amd-ucode.img \
        --cmdline /etc/kernel/cmdline \
        --efi-stub /usr/lib/systemd/boot/efi/linuxx64.efi.stub \
        --esp /boot/efi \
        --initramfs /boot/initramfs-linux-hardened.img \
        --intelucode /boot/intel-ucode.img \
        --kernel-img /boot/vmlinuz-linux-hardened \
        --os-release /etc/os-release \
        --save \
        /boot/efi/EFI/arch-linux.efi
    chroot /mnt sbctl bundle \
        --amducode /boot/amd-ucode.img \
        --cmdline /etc/kernel/cmdline \
        --efi-stub /usr/lib/systemd/boot/efi/linuxx64.efi.stub \
        --esp /boot/efi \
        --initramfs /boot/initramfs-linux-hardened-fallback.img \
        --intelucode /boot/intel-ucode.img \
        --kernel-img /boot/vmlinuz-linux-hardened \
        --os-release /etc/os-release \
        --save \
        /boot/efi/EFI/arch-linux-(fallback).efi
    chroot /mnt sbctl list-bundles
    sleep 2

    echo "[*] Generating a UEFI boot entry..."
    efibootmgr --create --disk $DISK --part 1 --label 'arch-linux' --loader '\EFI\arch-linux.efi' --unicode
    sleep 2
else
    echo "[X] ERROR: Variable 'UEFI' is "$UEFI" but must be 0 or 1. Exiting..."
    exit 1
fi

# CONFIGURE LIBVIRTD
echo "[*] Configuring libvirtd..."
echo "unix_sock_group = \"libvirt\"" | tee -a /mnt/etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | tee -a /mnt/etc/libvirt/libvirtd.conf
chroot /mnt systemctl enable libvirtd.service

# CONFIGURE NETWORKING
echo "[*] Configuring network services..."
chroot /mnt systemctl enable dhcpcd
chroot /mnt systemctl enable NetworkManager.service

echo "[*] Setting up the hostname..."
echo $HOSTNAME > /mnt/etc/hostname

echo "[*] Populating '/etc/hosts'..."
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts

# SETUP LOCALE
echo "[*] Setting up the locale..."
arch-chroot /mnt /bin/bash -c "\
    echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen;\
    locale-gen;\
    echo \"LANG=en_US.UTF-8\" > /etc/locale.conf;\
    export LANG=en_US.UTF-8;\
    echo \"KEYMAP=de-latin1\" > /etc/vconsole.conf;\
    echo \"FONT=lat9w-16\" >> /etc/vconsole.conf"

# SETUP TIME
echo "[*] Setting up the hardware clock..."
chroot /mnt hwclock --systohc --utc

echo "[*] Setting up the timezone..."
chroot /mnt ln /usr/share/zoneinfo/Europe/Berlin /etc/localtime
chroot /mnt timedatectl set-timezone Europe/Berlin

echo "[*] Enabling network time synchronisation..."
chroot /mnt timedatectl set-ntp true
sleep 2

# SETUP KEYBOARD LAYOUT
echo "[*] Loading German keyboard layout..."
arch-chroot /mnt /bin/bash -c "\
    loadkeys de-latin1;\
    localectl set-keymap de"
sleep 2

# USER MANAGEMENT
echo "[*] Adding the home user '$USER_NAME'..."
useradd --root /mnt -m $USER_NAME -G users
usermod --root /mnt --append --groups libvirt $USER_NAME
usermod --root /mnt --append --groups wheel $USER_NAME
sleep 2

echo "[*] Granting sudo rights to the home user..."
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers
echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers

echo "[*] Setting the home user password..."
echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt
sleep 2

echo "[*] Disabling the root account..."
passwd --root /mnt --lock root

echo "[*] Adding user paths & scripts..."
mkdir -p /mnt/home/$USER_NAME/tools
mkdir -p /mnt/home/$USER_NAME/workspace

echo "\
    sudo pacman --disable-download-timeout --needed --noconfirm -Syyu\n\
    yay --disable-download-timeout --needed --noconfirm -Syyu\n\
    sudo pacman --noconfirm -Rns \$(pacman -Qdtq)\n\
    sudo chmod 4755 /opt/*/chrome-sandbox\n"\
> /mnt/home/$USER_NAME/tools/update.sh

chroot /mnt chown -R $USER_NAME:users /home/$USER_NAME

sleep 2

# UNMOUNT FILESYSTEMS
echo "[*] Unmounting filesystems..."
sync
umount -a

# STOP MESSAGE
echo "[*] Work done. Exiting..."
exit 0
