# Global variables
USER="user"

# System update
echo "Updating the system..."
sudo pacman --disable-download-timeout --needed --noconfirm -Syu

# Install required packages
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

# Configure the libvirtd service
sudo systemctl enable --now libvirtd
sudo systemctl status libvirtd

echo "unix_sock_group = \"libvirt\"" | sudo tee -a /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0770\"" | sudo tee -a /etc/libvirt/libvirtd.conf

sudo usermod -a -G libvirt $USER

sudo systemctl restart libvirtd
sudo systemctl status libvirtd

# Enable nested virtualisation
echo "options kvm-amd nested=1" | sudo tee /etc/modprobe.d/kvm-amd.conf
echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf
