# Global variables
TMP_PATH="/tmp/yay-bin/"
USER_NAME=$(whoami)

# Temporary install Git
sudo pacman --disable-download-timeout --needed --noconfirm -S gitx

# Retrieve yay
git clone https://aur.archlinux.org/yay-bin.git "$TMP_PATH"
cd "$TMP_PATH"

# Install yay
makepkg --noconfirm -si
cd
yay --version

# Install required tools
TOOLS="chkrootkit secure-delete"

for Tool in $TOOLS; do
    sudo pacman --disable-download-timeout --needed --noconfirm -S $Tool
    yay --disable-download-timeout --needed --noconfirm -S $Tool
done

# Uninstall Git
sudo pacman --noconfirm -Rns git

# Cleanup
srm -v -r $(readlink -f $0)
srm -v -r "$TMP_PATH"

sudo pacman --noconfirm -Rns $(pacman -Qdtq)
