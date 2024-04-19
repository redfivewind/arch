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
    GROUPS="audio netdev plugdev video"
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
    echo "[*] Please select the disk where Alpine Linux should be installed into: "
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
    #FIXME
}

_01_04_02_prep_update_pkg_mgr() {
    #FIXME
}

_01_04_03_prep_install_pkgs() {
    #FIXME
}

_01_04_04_prep_enable_udev() {
    #FIXME
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
    #FIXME
}

_02_00() {
    echo "[*] --------- STAGE: 02 - MAIN INSTALLATION ---------"
    _02_01_install_sys
}

_02_01_install_sys() {
    #FIXME
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
    #FIXME
}

_03_02_00_net() {
    echo "[*] Enabling networking within the new system..."
    _03_02_01_net_enable_dns_resolution
    _03_02_02_net_set_hostname
    _03_02_03_net_populate_hostsfile
}

_03_02_01_net_enable_dns_resolution() {
    #FIXME
}

_03_02_02_net_set_hostname() {
    #FIXME
}

_03_02_03_net_populate_hostsfile() {
    #FIXME
}

_03_03_00_kernel() {
    echo "[*] Adjusting kernel configuration files..."
    _03_03_01_kernel_cfg_crypttab
    _03_03_02_kernel_cfg_fstab
}

_03_03_01_kernel_cfg_crypttab() {
    #FIXME
}

_03_03_02_kernel_cfg_fstab() {
    echo "[*] Setting 'noatime' within the fstab file..."
    sed -i 's/relatime/noatime/g' /mnt/etc/fstab
    cat /mnt/etc/fstab
    sleep 2
}

_03_04_00_ramdisk() {
    #FIXME
}

_03_05_00_region() {
    echo "[*] Setting up the region..."
    _03_05_01_region_setup_keymap
    _03_05_02_region_setup_locale
    _03_05_03_00_region_setup_time
}

_03_05_01_region_setup_keymap() {
    #FIXME
}

_03_05_02_region_setup_locale() {
    #FIXME
}

_03_05_03_00_region_setup_time() {
    #FIXME
}

_03_06_setup_boot_env() {
    #FIXME
}

_03_07_install_pkgs() {
    #FIXME
}

_03_08_00_services() {
    echo "[*] Configuring services..."
    _03_08_01_services_disable
    _03_08_02_services_enable
}

_03_08_01_services_disable() {
    #FIXME
}

_03_08_02_services_enable() {
    #FIXME
}

_03_09_00_user() {
    echo "[*] User management..."
    _03_09_01_user_add
    _03_09_02_user_set_pass
    _03_09_03_user_add_groups
    _03_09_04_user_init_env
    _03_09_05_user_root_lock
}

_03_09_01_user_add() {
    #FIXME
}

_03_09_02_user_set_pass() {
    echo "[*] Setting the user password..."
    echo -n "$USER_NAME:$USER_PASS" | chpasswd -R /mnt
}

_03_09_03_user_add_groups() {
    echo "[*] Adding user '$USER_NAME' to required groups..."

    for group in $GROUPS;
    do        
        chroot /mnt addgroup -S $group
        chroot /mnt adduser $USER_NAME $group
    done
}

_03_09_04_user_init_env() {
    #FIXME    
}

_03_09_05_user_root_lock() {
    echo "[*] Locking the root account..."
    chroot /mnt passwd -l root
}

_03_10_unmount_fs() {
    #FIXME
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
