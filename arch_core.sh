_01_00() {
    echo "[*] --------- STAGE: 01 - PRE INSTALLATION ---------"
    _01_01_start_msg
    _01_02_init_global_vars
    _01_03_00_prompt_user
    _01_04_00_prep
    _01_05_part_disk
    _01_06_setup_lvm
    _01_07_mount_partitions
}

_01_01_start_msg() {
    echo "[*] This script installs Arch Linux on this system."
    echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
    read
}

_01_02_init_global_vars() {
    echo "[*] Initialising global variables..."
    DISK=""
    GROUP_ARRAY="audio netdev plugdev video wheel"
    HOSTNAME="localhost"
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
    UEFI_UKI="/boot/efi/EFI/arch-linux.efi"
    USER_NAME="user"
    USER_PASS=""
}

_01_03_00_prompt_user() {
    echo "[*] Querying user input..."
    _01_03_01_prompt_user_platform
    _01_03_02_prompt_user_disk
    _01_03_03_prompt_user_pass_luks
    _01_03_04_prompt_user_pass_user
    #_01_03_05_prompt_user_audio
    #_01_03_06_prompt_user_gpu
    #_01_03_07_prompt_user_keymap
    #_01_03_08_prompt_user_locale
    #_01_03_09_prompt_user_timezone
}

_01_03_01_prompt_user_platform() {
    echo "[*] Please select the plaform ('bios' or 'uefi'): "
    read platform
    platform=$(echo "$platform" | tr '[:upper:]' '[:lower:]')

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
}

_01_03_02_prompt_user_disk() {
    echo "[*] Retrieving available disks..."
    echo
    fdisk -l
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
        
                if (echo "$DISK" | grep -q "^/dev/mmc"); 
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
                elif (echo "$DISK" | grep -q "^/dev/nvme"); 
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
}

_01_03_03_prompt_user_pass_luks() {
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
}

_01_03_04_prompt_user_pass_user() {
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
}

_01_03_05_prompt_user_audio() {
    #FIXME
    return
}

_01_03_06_prompt_user_gpu() {
    #FIXME
    return
}

_01_03_07_prompt_user_keymap() {
    #FIXME
    return
}

_01_03_08_prompt_user_locale() {
    #FIXME
    return
}

_01_03_09_prompt_user_timezone() {
    #FIXME
    return
}

_01_04_00_prep() {
    echo "[*] Preparing the installation..."
    _01_04_01_prep_cfg_pkg_mgr
    _01_04_02_prep_update_pkg_mgr
    _01_04_03_prep_install_pkgs
    _01_04_04_prep_enable_udev
}

_01_04_01_prep_cfg_pkg_mgr() {
    echo "[*] Skipping configuration of pacman..."
}

_01_04_02_prep_update_pkg_mgr() {
    echo "[*] Updating the pacman database..."
    #pacman --disable-download-timeout --noconfirm -Scc
    pacman --disable-download-timeout --noconfirm -Syy
}

_01_04_03_prep_install_pkgs() {
    echo "[*] Skipping installation of packages..."
}

_01_04_04_prep_enable_udev() {
    echo "[*] Skipping configuration of udev..."
}

_01_05_part_disk() {
    echo "[*] Partitioning the disk..."

    if [ "$UEFI" == 0 ];
    then
        echo "[*] Partitioning the target disk using MBR partition layout..."
        parted $DISK --script mktable msdos

        echo "[*] Creating the LUKS partition..."
        parted $DISK --script mkpart primary ext4 0% 100%
        parted $DISK --script set 1 boot on

        echo "[*] Formatting the LUKS partition..."
        echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks1 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
        echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
        sleep 2

        echo "[*] Synchronising..."
        sync
    elif [ "$UEFI" == 1 ];
    then
        echo "[*] Partitioning the target disk using GPT partition layout..."
        parted $DISK --script mktable gpt

        echo "[*] Creating the EFI partition..."
        parted $DISK --script mkpart primary fat32 1MiB 512MiB 
        parted $DISK --script set 1 boot on 
        parted $DISK --script set 1 esp on
        parted $DISK --script name 1 $PART_EFI_LABEL

        echo "[*] Formatting the EFI partition..."
        mkfs.vfat $PART_EFI

        echo "[*] Creating the LUKS partition..."
        parted $DISK --script mkpart primary ext4 512MiB 100%
        parted $DISK --script name 2 $PART_LUKS_LABEL

        echo "[*] Formatting the LUKS partition..."
        echo -n $LUKS_PASS | cryptsetup luksFormat $PART_LUKS --type luks2 -c twofish-xts-plain64 -h sha512 -s 512 --iter-time 10000 -
        echo -n $LUKS_PASS | cryptsetup luksOpen $PART_LUKS $LUKS_LVM -
        sleep 2

        echo "[*] Synchronising..."
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
}

_01_06_setup_lvm() {
    echo "[*] Setting up LVM..."

    echo "[*] Creating physical device '$LUKS_LVM'..."
    pvcreate /dev/mapper/$LUKS_LVM

    echo "[*] Creating volume group '$LVM_VG'..."
    vgcreate $LVM_VG /dev/mapper/$LUKS_LVM

    echo "[*] Setting up logical volume '$LV_SWAP'..."
    lvcreate -L 6144M $LVM_VG -n $LV_SWAP
    mkswap /dev/mapper/$LVM_VG-$LV_SWAP -L $LV_SWAP

    echo "[*] Setting up logical volume '$LV_ROOT'..."
    lvcreate -l 100%FREE $LVM_VG -n $LV_ROOT
    mkfs.ext4 /dev/mapper/$LVM_VG-$LV_ROOT

    lvscan
    sleep 2
}

_01_07_mount_partitions() {
    echo "[*] Mounting required partitions..."

    echo "[*] Mounting the root partition..."
    mount -t ext4 /dev/$LVM_VG/$LV_ROOT /mnt
    
    if [ "$UEFI" == 0 ];
    then
        echo "[*] Skipping the EFI partition because the selected platform is BIOS..."
    elif [ "$UEFI" == 1 ];
    then
        echo "[*] Mounting the EFI partition..."
        mkdir -p /mnt/boot/efi
        mount $PART_EFI /mnt/boot/efi
        mkdir /mnt/boot/efi/EFI
    else
        echo "[X] ERROR: Variable 'UEFI' is '$UEFI' but must be 0 or 1. Exiting..."
        exit 1
    fi
    
    echo "[*] Mounting the swap partition..."
    swapon /dev/$LVM_VG/$LV_SWAP
    sleep 2
}

_02_00() {
    echo "[*] --------- STAGE: 02 - MAIN INSTALLATION ---------"
    _02_01_install_sys
}

_02_01_install_sys() {
    echo "[*] Bootstrapping Arch Linux into /mnt including base packages..."
    pacstrap /mnt amd-ucode arch-audit base base-devel dhcpcd gptfdisk gvfs intel-ucode iptables-nft iwd linux-firmware linux-hardened lvm2 mkinitcpio nano networkmanager net-tools p7zip pavucontrol pulseaudio pulseaudio-alsa sudo unzip zip
    sleep 2
}

_03_00() {
    echo "[*] --------- STAGE: 03 - POST INSTALLATION ---------"
    _03_01_mount_fs
    _03_02_00_net
    _03_03_00_kernel
    _03_04_00_ramdisk
    _03_05_00_region
    _03_06_setup_boot_env
    _03_07_install_pkgs
    _03_08_00_services
    _03_09_00_user
    _03_10_unmount_fs
    _03_11_stop_msg
}

_03_01_mount_fs() {
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
}

_03_02_00_net() {
    echo "[*] Enabling networking within the new system..."
    _03_02_01_net_enable_dns_resolution
    _03_02_02_net_set_hostname
    _03_02_03_net_populate_hostsfile
}

_03_02_01_net_enable_dns_resolution() {
    echo "[*] Copying '/etc/resolv.conf' to '/mnt' to enable DNS resolution within the new system's root..."
    cp /etc/resolv.conf /mnt/etc/resolv.conf
}

_03_02_02_net_set_hostname() {
    echo "[*] Setting up the hostname..."
    echo $HOSTNAME > /mnt/etc/hostname
}

_03_02_03_net_populate_hostsfile() {
    echo "[*] Populating the hosts file..."
    echo "127.0.0.1 $HOSTNAME" | tee /etc/hosts
    echo "::1 $HOSTNAME" | tee -a /etc/hosts
}

_03_03_00_kernel() {
    echo "[*] Adjusting kernel configuration files..."
    _03_03_01_kernel_cfg_crypttab
    _03_03_02_kernel_cfg_fstab
}

_03_03_01_kernel_cfg_crypttab() {
    echo "[*] Adding the LUKS partition to /etc/crypttab..."
    printf "${LUKS_LVM}\tUUID=%s\tnone\tluks\n" "$(cryptsetup luksUUID $PART_LUKS)" | tee -a /mnt/etc/crypttab
    cat /mnt/etc/crypttab
}

_03_03_02_kernel_cfg_fstab() {
    if [ "$UEFI" == 0 ];
    then
        echo "[*] Adding the EFI partition to '/etc/fstab'..."
        printf "UUID=$(blkid -o value -s UUID $PART_EFI)\t/boot/efi\tvfat\tdefaults,noatime\t0 1" | tee -a /mnt/etc/fstab
    fi

    echo "[*] Setting 'noatime' within the fstab file..."
    sed -i 's/relatime/noatime/g' /mnt/etc/fstab
    cat /mnt/etc/fstab
    sleep 2
}

_03_04_00_ramdisk() {
    echo "[*] Rebuilding initramfs image using mkinitcpio..."
    echo "MODULES=()" > /mnt/etc/mkinitcpio.conf
    echo "BINARIES=()" >> /mnt/etc/mkinitcpio.conf
    echo "HOOKS=(base udev keyboard keymap autodetect modconf kms block filesystems fsck encrypt lvm2)" >> /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux-hardened"
    sleep 2
}

_03_05_00_region() {
    echo "[*] Setting up the region..."
    _03_05_01_region_setup_keymap
    _03_05_02_region_setup_locale
    _03_05_03_00_region_setup_time
}

_03_05_01_region_setup_keymap() {
    echo "[*] Setting up the keymap..."
    echo "KEYMAP=de" > /mnt/etc/vconsole.conf
    echo "FONT=lat9w-16" > /mnt/etc/vconsole.conf
}

_03_05_02_region_setup_locale() {
    echo "[*] Setting up the locale..."
    echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
    arch-chroot /mnt /bin/bash -c "locale-gen"    
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf;
    arch-chroot /mnt /bin/bash -c "export LANG=en_US.UTF-8"
}

_03_05_03_00_region_setup_time() {
    echo "[*] Setting up the time..."
    arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
    ln -sf /mnt/usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime
}

_03_06_setup_boot_env() {
    echo "[*] Setting up the boot environment..."

    echo "[*] Updating the kernel cmdline..."
    KERNEL_CMDLINE="cryptdevice=UUID=$(cryptsetup luksUUID $PART_LUKS):$LUKS_LVM root=/dev/$LVM_VG/$LV_ROOT rw"
    echo "$KERNEL_CMDLINE" > /mnt/etc/kernel/cmdline
        
    if [ "$UEFI" == 0 ];
    then
        echo "[*] Skipping package 'efibootmgr'..."    
    
        arch-chroot /mnt /bin/bash -c "\
            echo \"[*] Installing the GRUB2 package...\";\
            pacman --disable-download-timeout --needed --noconfirm -S grub"
    
        echo "[*] Preapring GRUB2 to support booting from the LUKS partition..."
        echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
        sed -i 's/GRUB_CMDLINE_LINUX=""/#GRUB_CMDLINE_LINUX=""/' /mnt/etc/default/grub
        #echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$(cryptsetup luksUUID $PART_LUKS):$LUKS_LVM root=/dev/$LVM_VG/$LV_ROOT\"" >> /mnt/etc/default/grub
        echo "GRUB_CMDLINE_LINUX=\"$KERNEL_CMDLINE\"" >> /mnt/etc/default/grub
        echo "GRUB_PRELOAD_MODULES=\"cryptodisk part_msdos\"" >> /mnt/etc/default/grub
        tail /mnt/etc/default/grub
        sleep 2
    
        arch-chroot /mnt /bin/bash -c "\
            echo \"[*] Installing GRUB2 to disk...\";\
            grub-install $DISK;\
            
            echo \"[*] Generating a GRUB2 configuration file...\";\
            grub-mkconfig -o /boot/grub/grub.cfg"
    elif [ "$UEFI" == 1 ];
    then
        arch-chroot /mnt /bin/bash -c "\
            echo '[*] Installing required packages...';\
            pacman --disable-download-timeout --needed --noconfirm -S efibootmgr sbctl;\
        
            echo '[*] Generating signing keys for UEFI Secure Boot...';\
            sbctl create-keys;\
    
            echo '[*] Enrolling the signing keys for UEFI Secure Boot...';\
            sbctl enroll-keys --ignore-immutable --microsoft;\
        
            echo '[*] Generating a unified kernel image for Arch Linux...';\
            sbctl bundle --amducode /boot/amd-ucode.img \
                --cmdline /etc/kernel/cmdline \
                --initramfs /boot/initramfs-linux-hardened.img \
                --intelucode /boot/intel-ucode.img \
                --kernel-img /boot/vmlinuz-linux-hardened \
                --save \
                /boot/efi/EFI/arch.efi;\
    
            echo '[*] Signing the unified kernel image...';\
            sbctl sign /boot/efi/EFI/arch.efi;\
            
            echo '[*] Creating a boot entry...';\
            efibootmgr --disk $DISK --part 1 --create --label 'arch' --load '\EFI\arch.efi' --verbose;\
            efibootmgr -v;\
            sleep 3"
    else
        echo "[X] ERROR: Variable 'UEFI' is "$UEFI" but must be 0 or 1. Exiting..."
        exit 1
    fi
}

_03_07_install_pkgs() {
    echo "[*] Skipping installation of packages..."
}

_03_08_00_services() {
    echo "[*] Configuring services..."
    _03_08_01_services_disable
    _03_08_02_services_enable
}

_03_08_01_services_disable() {
    echo "[*] Skipping disabling of services..."
}

_03_08_02_services_enable() {
    arch-chroot /mnt /bin/bash -c "\
        systemctl enable dhcpcd;\
        systemctl enable NetworkManager.service;\
        systemctl enable systemd-timesyncd;\
        systemctl enable tlp.service"
}

_03_09_00_user() {
    echo "[*] User management..."
    _03_09_01_user_add
    _03_09_02_user_set_pass
    _03_09_03_user_add_groups
    _03_09_04_user_set_permissions
    _03_09_05_user_init_env
    _03_09_06_user_root_lock
}

_03_09_01_user_add() {
    echo "[*] Adding the home user '$USER_NAME'..."
    useradd --root /mnt -m $USER_NAME -G users
}

_03_09_02_user_set_pass() {
    echo "[*] Setting the user password..."
    echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt
}

_03_09_03_user_add_groups() {
    echo "[*] Adding user '$USER_NAME' to required groups..."

    for group in $GROUP_ARRAY;
    do        
        groupadd --root /mnt --force $group
        usermod --root /mnt --append --groups $group $USER_NAME
    done
}

_03_09_04_user_set_permissions() {
    echo "[*] Granting sudo rights to the home user..."
    echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers
    echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers
}

_03_09_05_user_init_env() {
    echo "[*] Adding user paths & scripts..."
    mkdir -p /mnt/home/$USER_NAME/tools
    mkdir -p /mnt/home/$USER_NAME/workspace
    
    echo "sudo pacman --disable-download-timeout --needed --noconfirm -Syyu" > /mnt/home/$USER_NAME/tools/update.sh
    echo "yay --disable-download-timeout --needed --noconfirm -Syyu" >> /mnt/home/$USER_NAME/tools/update.sh
    echo "sudo pacman --noconfirm -Rns \$(pacman -Qdtq)" >> /mnt/home/$USER_NAME/tools/update.sh
    echo "sudo chmod 4755 /opt/*/chrome-sandbox" >> /mnt/home/$USER_NAME/tools/update.sh
    
    chroot /mnt chown -R $USER_NAME:users /home/$USER_NAME   
}

_03_09_06_user_root_lock() {
    echo "[*] Locking the root account..."
    chroot /mnt passwd -l root
}

_03_10_unmount_fs() {
    echo "[*] Unmounting filesystems..."
    sync
    umount -a
}

_03_11_stop_msg() {
    echo "[*] Installation of Arch Linux completed. You may reboot now."
    echo "[*] Work done. Exiting..."
    sync
    exit 0
}

main() {
    # Stage 1: Pre installation
    _01_00

    # Stage 2: Main installation
    _02_00

    # Stage 3: Post installation
    _03_00
}

main
