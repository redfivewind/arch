# Update all packages" > /home/$USER_NAME/tools/update.sh
sudo pacman --disable-download-timeout --needed --noconfirm -Syyu
yay --disable-download-timeout --needed --noconfirm -Syyu

# Autoremove packages that are no longer required
sudo pacman --noconfirm -Rns $(pacman -Qdtq)

# Fix the chrome-sandbox bug
sudo chmod 4755 /opt/*/chrome-sandbox
