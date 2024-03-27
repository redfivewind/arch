#AUDIO: Yes/No
#DESKTOP: -, Hyprland, XFCE
#GPU: AMD/ATI, Intel, NVIDIA
#HYPERVISOR: -, KVM, XEN
#NETWORKING: ???
#PLATFORM: BIOS, UEFI, UEFI Secure Boot
#SECURITY: EDR, Disable shell history, ...

# Start message
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# Initialise global variables
echo "[*] Initialising global variables..."
#FIXME

# Parse arguments
echo "[*] Parsing arguments..."
#FIXME

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
    base-devel \
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
    pavucontrol \
    pulseaudio \
    pulseaudio-alsa \
    rkhunter \
    sudo \
    thermald \
    tlp \
    unrar \
    unzip \
    wpa_supplicant \
    zip
sleep 2
