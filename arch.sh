#AUDIO: Yes/No
#DESKTOP: -, Hyprland, XFCE
#GPU: AMD/ATI, Intel, NVIDIA
#HYPERVISOR: -, KVM, XEN
#LOCALE: en_US.UTF-8?
#NETWORKING: ???
#SECURITY: EDR, Disable shell history, ...
#TIME: Date format, Timezone

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Initialise global variables
echo "[*] Initialising global variables..."
BIOS=""
DISK=""
KERNEL="linux-hardened"
LUKS_LVM="luks_lvm"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
PART_EFI=""
PART_LUKS=""
USER_NAME="user"
USER_PASS=""

# Retrieve the platform
echo "[*] Please enter the target platform ('bios' or 'uefi')..."
read platform

if [ -z "$platform" ];
then
    echo "[X] ERROR: The entered target platform is empty. Exiting..."
    exit 1
else
    if [ "$platform" == "bios" ];
    then
        echo "[*] Installing for platform BIOS..."
        BIOS=1
    elif [ "$platform" == "uefi" ];
    then
        echo "[*] Installing for platform UEFI..."
        BIOS=0
    else
        echo "[X] ERROR: The entered target platform is "$platform" but must be 'bios' or 'uefi'. Exiting..."
        exit 1
    fi
fi

# Retrieve the LUKS password
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

# Retrieve the user password
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

# Update the pacman database
echo "[*] Updating the pacman database..."
pacman --disable-download-timeout --noconfirm -Scc
pacman --disable-download-timeout --noconfirm -Syy

# Network time synchronisation
echo "[*] Enabling network time synchronization..."
timedatectl set-ntp true

# Partition the disk
echo "[*] Partitioning the disk..."
#FIXME

# Setup LUKS
echo "[*] Setting up LUKS..."
echo "[*] Formatting the second partition as LUKS crypto partition..."
echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LVM_LUKS -
sleep 2

# Setup LVM 
echo "[*] Setting up LVM..."
pvcreate /dev/mapper/$LVM_LUKS
vgcreate $VG_LUKS /dev/mapper/$LVM_LUKS
lvcreate -L 6144M $VG_LUKS -n $LV_SWAP
lvcreate -l 100%FREE $VG_LUKS -n $LV_ROOT
sleep 2

# Format & mount partitions
echo "[*] Formatting & mounting the partitions..."
#FIXME

# Install base packages
echo "[*] Bootstrapping Arch Linux into /mnt including base packages..."
pacstrap /mnt \
    amd-ucode \
    base \
    dhcpcd \
    gptfdisk \
    grub \
    gvfs \
    intel-ucode \
    iptables-nft \
    iwd \
    $KERNEL \
    linux-firmware \
    lvm2 \
    mkinitcpio \
    nano \
    networkmanager \
    net-tools \
    p7zip \
    rkhunter \
    sudo \
    tlp \
    unzip \
    zip
sleep 2

# Mount or create necessary entry points
echo "[*] Mounting necessary filesystems..."
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts /dev/pts /mnt/dev/pts/
mount -o bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars    
sleep 2

# fstab
echo "[*] Generating fstab file and setting the 'noatime' property..."
genfstab -U /mnt > /mnt/etc/fstab
sed -i 's/relatime/noatime/g' /mnt/etc/fstab
sleep 2

# German keyboard layout
echo "[*] Loading German keyboard layout..."
arch-chroot /mnt /bin/bash -c "\
    loadkeys de-latin1;\
    localectl set-keymap de"
sleep 2

# Network time synchronisation
echo "[*] Enabling network time synchronization..."
arch-chroot /mnt /bin/bash -c "\
    timedatectl set-ntp true"
sleep 2

# System update
echo "[*] Updating the system..."
arch-chroot /mnt /bin/bash -c "\
    pacman --disable-download-timeout --noconfirm -Scc;\
    pacman --disable-download-timeout --noconfirm -Syyu"
sleep 2

# Time
echo "[*] Setting the timezone & hardware clock..."
arch-chroot /mnt /bin/bash -c "\
    timedatectl set-timezone Europe/Berlin;\
    ln /usr/share/zoneinfo/Europe/Berlin /etc/localtime;\
    hwclock --systohc --utc"
sleep 2

# Locale
echo "[*] Initializing the locale..."
arch-chroot /mnt /bin/bash -c "\
    echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen;\
    locale-gen;\
    echo \"LANG=en_US.UTF-8\" > /etc/locale.conf;\
    export LANG=en_US.UTF-8;\
    echo \"KEYMAP=de-latin1\" > /etc/vconsole.conf;\
    echo \"FONT=lat9w-16\" >> /etc/vconsole.conf"

# Network
echo "[*] Setting hostname and /etc/hosts..."
echo $HOSTNAME > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
arch-chroot /mnt /bin/bash -c "\
    systemctl enable dhcpcd"

# mkinitcpio
echo "[*] Adding the LUKS partition to /etc/crypttab..."
printf "${LVM_LUKS}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /mnt/etc/crypttab
cat /mnt/etc/crypttab
