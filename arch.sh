#REGION: Locale - Timezone - Keyboard
#SECURITY: EDR, Disable shell history, ...
#YAY

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Initialise global variables
echo "[*] Initialising global variables..."
AUDIO=""
DESKTOP=""
DISK=""
GPU_AMD=""
GPU_INTEL=""
GPU_NVIDIA=""
HOSTNAME="MacBookAirM1"
KERNEL="linux-hardened"
LUKS_LVM="luks_lvm"
LUKS_PASS=""
LV_ROOT="lv_root"
LV_SWAP="lv_swap"
LVM_VG="lvm_vg"
NETWORKING=""
PART_EFI=""
PART_LUKS=""
UEFI=""
USER_NAME="user"
USER_PASS=""
XEN=""

# Select the target platform (BIOS or UEFI)
echo "[*] Please select the target plaform ('bios' or 'uefi')..."
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
    echo "[X] ERROR: Variable 'platform' is "$platform" but must be 'bios' or 'uefi'. Exiting..."
    exit 1
fi

# Select the hypervisor (KVM or Xen)
echo "[*] Please select the hypervisor ('kvm' or 'xen')..."
read hypervisor
hypervisor="${hypervisor,,}"

if [ "$hypervisor" == "kvm" ];
then
    echo "[*] Hypervisor: '$hypervisor'..."
    XEN=0
elif [ "$hypervisor" == "uefi" ];
then
    echo "[*] Hypervisor: '$hypervisor'..."
    XEN=1
else
    echo "[X] ERROR: Variable 'hypervisor' is "$hypervisor" but must be 'kvm' or 'xen'. Exiting..."
    exit 1
fi

# Enable/disable networking
echo "[*] Enable networking? (yes/no)"
read networking
networking="${networking,,}"

if [ "$networking" == "no" ];
then
    echo "[*] Networking enabled: '$networking'"
    NETWORKING=0
elif [ "$networking" == "yes" ];
then
    echo "[*] Networking enabled: '$networking'"
    NETWORKING=1
else
    echo "[X] ERROR: Variable 'networking' is '$networking' but must be 'yes' or 'no'. Exiting..."
    exit 1
fi

# Enable/disable (proprietary) GPU drivers
echo "[*] Enable AMD GPU drivers? (yes/no)"
read gpu_amd
gpu_amd="${gpu_amd,,}"

if [ "$gpu_amd" == "no" ];
then
    echo "[*] AMD GPU drivers enabled: '$gpu_amd'"
    GPU_AMD=0
elif [ "$gpu_amd" == "yes" ];
then
    echo "[*] AMD GPU drivers enabled: '$gpu_amd'"
    GPU_AMD=1
else
    echo "[X] ERROR: Variable 'gpu_amd' is '$gpu_amd' but must be 'yes' or 'no'. Exiting..."
    exit 1
fi

echo "[*] Enable Intel GPU drivers? (yes/no)"
read gpu_intel
gpu_intel="${gpu_intel,,}"

if [ "$gpu_intel" == "no" ];
then
    echo "[*] Intel GPU drivers enabled: '$gpu_intel'"
    GPU_INTEL=0
elif [ "$gpu_intel" == "yes" ];
then
    echo "[*] Intel GPU drivers enabled: '$gpu_intel'"
    GPU_INTEL=1
else
    echo "[X] ERROR: Variable 'gpu_intel' is '$gpu_intel' but must be 'yes' or 'no'. Exiting..."
    exit 1
fi

echo "[*] Enable NVIDIA GPU drivers? (yes/no)"
read gpu_nvidia
gpu_nvidia="${gpu_nvidia,,}"

if [ "$gpu_nvidia" == "no" ];
then
    echo "[*] NVIDIA GPU drivers enabled: '$gpu_nvidia'"
    GPU_NVIDIA=0
elif [ "$gpu_nvidia" == "yes" ];
then
    echo "[*] NVIDIA GPU drivers enabled: '$gpu_nvidia'"
    GPU_NVIDIA=1
else
    echo "[X] ERROR: Variable 'gpu_nvidia' is '$gpu_nvidia' but must be 'yes' or 'no'. Exiting..."
    exit 1
fi

# Enable/disable audio
echo "[*] Enable audio? (yes/no)"
read audio
audio="${audio,,}"

if [ "$audio" == "no" ];
then
    echo "[*] Audio enabled: '$audio'"
    AUDIO=0
elif [ "$audio" == "yes" ];
then
    echo "[*] Audio enabled: '$audio'"
    AUDIO=1
else
    echo "[X] ERROR: Variable 'audio' is '$audio' but must be 'yes' or 'no'. Exiting..."
    exit 1
fi

# Select the desktop environment (optional)
echo "[*] Please select the desktop environment ('-', 'hyprland' or 'xfce')..."
read desktop
desktop="${desktop,,}"

if [ "$desktop" == "none" ];
then
    echo "[*] Desktop: '$desktop'"
    DESKTOP="$desktop"
elif [ "$desktop" == "hyprland" ];
then
    echo "[*] Desktop: '$desktop'"
    DESKTOP="$desktop"
elif [ "$desktop" == "xfce" ];
then
    echo "[*] Desktop: '$desktop'"
    DESKTOP="$desktop"
else
    echo "[X] ERROR: Variable 'desktop' is '$desktop' but must be '-', 'hyprland' or 'xfce'. Exiting..."
    exit 1
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

# Partition the disk
echo "[*] Partitioning the disk..."

if [ "$UEFI" == 0 ];
then
    echo "[*] Partitioning the target disk using MBR partition layout..."
    parted $DISK mktable msdos
    
    parted $DISK mkpart primary ext4 0% 100%
    parted $DISK set 1 boot on
    parted $DISK name 1 $PART_LUKS_LABEL

    sync
elif [ "$UEFI" == 1 ];
then
    echo "[*] Partitioning the target disk using GPT partition layout..."
    parted $DISK mktable gpt
    
    parted $DISK mkpart primary fat32 1MiB 512MiB 
    parted $DISK set 1 boot on 
    parted $DISK set 1 esp on
    parted $DISK name 1 $PART_EFI_LABEL
    
    parted $DISK mkpart primary ext4 512MiB 100%
    parted $DISK name 2 $PART_LUKS_LABEL

    sync
else
    echo "[X] ERROR: Variable 'UEFI' is "$UEFI" but must be 0 or 1. Exiting..."
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
    echo "[X] ERROR: Variable 'UEFI' is "$UEFI" but must be 0 or 1. Exiting..."
    exit 1
fi

echo "[*] Processing the root partition..."
mkfs.ext4 /dev/mapper/$LVM_VG-$LV_ROOT
mount -t ext4 /dev/$LVM_VG/$LV_ROOT /mnt

echo "[*] Processing the swap partition..."
mkswap /dev/mapper/$LVM_VG-$LV_SWAP -L $LV_SWAP
swapon /dev/$LVM_VG/$LV_SWAP
sleep 2

# Update the pacman database
echo "[*] Updating the pacman database..."
pacman --disable-download-timeout --noconfirm -Scc
pacman --disable-download-timeout --noconfirm -Syy

# Bootstrap Arch Linux into /mnt
echo "[*] Bootstrapping Arch Linux into /mnt including base packages..."
pacstrap /mnt \
    amd-ucode \
    base \
    dhcpcd \ #FIXME
    gptfdisk \
    grub \ #FIXME
    gvfs \ #FIXME
    intel-ucode \
    iptables-nft \ #FIXME
    iwd \ #FIXME
    $KERNEL \
    linux-firmware \
    lvm2 \
    mkinitcpio \
    nano \
    networkmanager \ #FIXME
    net-tools \ #FIXME
    p7zip \
    rkhunter \ #FIXME
    sudo \
    tlp \ #FIXME
    unzip \
    zip
sleep 2

# Networking
if [ "$NETWORKING" == 0 ];
then
    #FIXME
elif [ "$NETWORKING" == 1 ];
then
    #FIXME
else
    echo "[*] Variable 'NETWORKING' is '$NETWORKING' but must be 0 or 1. Exiting..."
    exit 1
fi

# GPU
if [ "$GPU_AMD" == 0 ];
then
    #FIXME
elif [ "$GPU_AMD" == 1 ];
then
    #FIXME
else
    echo "[*] Variable 'GPU_AMD' is '$GPU_AMD' but must be 0 or 1. Exiting..."
    exit 1
fi

if [ "$GPU_INTEL" == 0 ];
then
    #FIXME
elif [ "$GPU_INTEL" == 1 ];
then
    #FIXME
else
    echo "[*] Variable 'GPU_INTEL' is '$GPU_INTEL' but must be 0 or 1. Exiting..."
    exit 1
fi

if [ "$GPU_NVIDIA" == 0 ];
then
    #FIXME
elif [ "$GPU_NVIDIA" == 1 ];
then
    #FIXME
else
    echo "[*] Variable 'GPU_NVIDIA' is '$GPU_NVIDIA' but must be 0 or 1. Exiting..."
    exit 1
fi

# Audio
if [ "$AUDIO" == 0 ];
then
    #FIXME
elif [ "$AUDIO" == 1 ];
then
    #FIXME
else
    echo "[*] Variable 'AUDIO' is '$AUDIO' but must be 0 or 1. Exiting..."
    exit 1
fi

# Mount required filesystems
echo "[*] Mounting required filesystems..."
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts /dev/pts /mnt/dev/pts/

if [ "$UEFI" == 0 ];
then
    echo "[*] Skipping '/sys/firmware/efi/efivars' because the selected platform is BIOS..."
if [ "$UEFI" == 1 ];
then
    echo "[*] Mounting '/sys/firmware/efi/efivars' because the selected platform is UEFI..."
    mount -o bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
else
    echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. Exiting..."
    exit 1
fi 

sleep 2

# /etc/crypttab
echo "[*] Adding the LUKS partition to /etc/crypttab..."
printf "${LVM_LUKS}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /mnt/etc/crypttab
cat /mnt/etc/crypttab

# fstab
echo "[*] Generating fstab file and setting the 'noatime' property..."
genfstab -U /mnt > /mnt/etc/fstab
sed -i 's/relatime/noatime/g' /mnt/etc/fstab
sleep 2

# mkinitcpio
echo "[*] Adding the LUKS partition to /etc/crypttab..."
printf "${LVM_LUKS}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /mnt/etc/crypttab
cat /mnt/etc/crypttab

echo "[*] Rebuilding initramfs image using mkinitcpio..."
echo "MODULES=()" > /mnt/etc/mkinitcpio.conf
echo "BINARIES=()" >> /mnt/etc/mkinitcpio.conf
echo "HOOKS=(autodetect base block encrypt filesystems fsck keyboard kms lvm2 modconf udev)" >> /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c "\
    mkinitcpio -p $KERNEL"
sleep 2

# Boot
echo "[*] Setting up the boot environment..."
#FIXME

# Keyboard layout
echo "[*] Loading German keyboard layout..."
arch-chroot /mnt /bin/bash -c "\
    loadkeys de-latin1;\
    localectl set-keymap de"
sleep 2

# Setup locale
echo "[*] Setting up the locale..."
arch-chroot /mnt /bin/bash -c "\
    echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen;\
    locale-gen;\
    echo \"LANG=en_US.UTF-8\" > /etc/locale.conf;\
    export LANG=en_US.UTF-8;\
    echo \"KEYMAP=de-latin1\" > /etc/vconsole.conf;\
    echo \"FONT=lat9w-16\" >> /etc/vconsole.conf"

# Timezone & hardware clock
echo "[*] Setting up the timezone & hardware clock..."
arch-chroot /mnt /bin/bash -c "\
    timedatectl set-timezone Europe/Berlin;\
    ln /usr/share/zoneinfo/Europe/Berlin /etc/localtime;\
    hwclock --systohc --utc"
sleep 2

# Network time synchronisation
echo "[*] Enabling network time synchronization..."
arch-chroot /mnt /bin/bash -c "\
    timedatectl set-ntp true"
sleep 2

# Update system
echo "[*] Updating the system..."
arch-chroot /mnt /bin/bash -c "\
    pacman --disable-download-timeout --noconfirm -Scc;\
    pacman --disable-download-timeout --noconfirm -Syyu"
sleep 2

# Setup the hostname & /etc/hosts
echo "[*] Setting up the hostname and /etc/hosts..."
echo $HOSTNAME > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
arch-chroot /mnt /bin/bash -c "\
    systemctl enable dhcpcd"


# User management
echo "[*] Adding the generic home user: '$USER_NAME'..."
arch-chroot /mnt /bin/bash -c "\
    useradd -m -G wheel,users $USER_NAME"

echo "[*] Granting sudo rights to the home user..."
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers
echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers

echo "[*] Setting the home user password..."
echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt
sleep 2

echo "[*] Disabling the root account..."
passwd --root /mnt --lock root

# Add user paths & scripts
echo "[*] Adding user paths & scripts..."
mkdir -p /mnt/home/$USER_NAME/tools
mkdir -p /mnt/home/$USER_NAME/workspace

echo "\
    sudo pacman --disable-download-timeout --needed --noconfirm -Syyu\n\
    yay --disable-download-timeout --needed --noconfirm -Syyu\n\
    sudo pacman --noconfirm -Rns \$(pacman -Qdtq)\n\
    sudo chmod 4755 /opt/*/chrome-sandbox\n"\
> /mnt/home/$USER_NAME/tools/update.sh

arch-chroot /mnt /bin/bash -c "\
    chown -R $USER_NAME:users /home/$USER_NAME"

# Unmount filesystems
echo "[*] Unmounting filesystems..."
sync
umount -a

# Stop message
echo "[*] Work done. Exiting..."
exit 0
