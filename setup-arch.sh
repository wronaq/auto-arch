#!/bin/sh

echo "--------------------------------------"
echo "---- Install additional packages -----"
echo "--------------------------------------"

pacman --noconfirm --needed -S base-devel sudo grub networkmanager dhclient neovim curl git ntp zsh


echo "--------------------------------------"
echo "--- Set Timezone, Clock and Locale ---"
echo "--------------------------------------"

ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=pl" >> /etc/vconsole.conf
echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf
echo "FONT_MAP=8859-2" >> /etc/vconsole.conf

echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"
grub-install --target=i386-pc $1
grub-mkconfig -o /boot/grub/grub.cfg


echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
systemctl enable systemd-networkd.service
systemctl enable NetworkManager.service
echo "Set up a wifi connection? [Y/n]"
read SETUP
[ $SETUP='Y' ] && echo 'Enter SSID:' && read SSID && echo 'Enter password:' && read -s PASSWORD && nmcli device wifi connect "${SSID}" password "${PASSWORD}"


echo "--------------------------------------"
echo "--      Set Password for Root       --"
echo "--------------------------------------"
echo "Enter password for root user: "
passwd root



echo "--------------------------------------"
echo "--           Set hostname           --"
echo "--------------------------------------"
echo "Please enter hostname:"
read HOSTNAME
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 "${HOSTNAME}".localdomain   "${HOSTNAME} >> /etc/hosts



echo "--------------------------------------"
echo "--             Add user             --"
echo "--------------------------------------"
echo "Please enter username:"
read USERNAME
useradd -m -g wheel -s /bin/zsh "$USERNAME" >/dev/null 2>&1 ||
usermod -aG wheel,audio,video,optical,disk,input,storage "$USERNAME" && mkdir -p /home/"$USERNAME" && chown "$USERNAME":wheel /home/"$USERNAME"
REPODIR="/home/$USERNAME/.local/src"; mkdir -p "$REPODIR"; chown -R "$USERNAME":wheel "$(dirname "$REPODIR")"
passwd $USERNAME

# set nopasswd for whole process of instalation
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers


