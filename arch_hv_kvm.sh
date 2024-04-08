# Start message
echo "[*] This script installs the KVM virtualisation infrastructure on this Arch Linux system."
echo "[!] ALERT: This script is potentially destructive. Use it on your own risk. Press any key to continue..."
read

# System update
echo "Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install required packages
echo "[*] Installing required packages..."
sudo pacman --disable-download-timeout --needed --noconfirm -S bridge-utils \
  dmidecode \
  dnsmasq \
  ebtables \
  edk2-ovmf \
  iptables-nft \
  libguestfs \
  libvirt \
  openbsd-netcat \
  qemu-full \
  seabios \
  vde2 \
  virt-manager \
  virt-viewer

# Configure libvirtd
echo "[*] Configuring the libvirtd service..."

echo "[*] Granting libvirt access to non-root users of the libvirt group..."
echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf

echo "[*] Adding the user '$(whoami)' to the libvirt group..."
sudo usermod -a -G libvirt $(whoami)

echo "[*] Enabling the libvirtd service..."
sudo systemctl enable libvirtd
sudo systemctl restart libvirtd
sudo systemctl status libvirtd

# Enable nested virtualisation
echo "[*] Enabling nested virtualisation..."
echo "options kvm-amd nested=1" | sudo tee /etc/modprobe.d/kvm-amd.conf
echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf

# Stop message
echo "[*] Work done. Exiting..."
exit 0
