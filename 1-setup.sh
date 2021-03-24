#!/usr/bin/env bash

echo "--------------------------------------"
echo "---- Install additional packages -----"
echo "--------------------------------------"

pacman -S base-devel vim sudo grub networkmanager dhclient --noconfirm --needed


echo "--------------------------------------"
echo "--- Set Timezone, Clock and Locale ---"
echo "--------------------------------------"

echo "Please enter country name: (example Poland)"
read COUNTRY_NAME
ln -sf /usr/share/zoneinfo/${COUNTRY_NAME,,} /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=${COUNTRY,,}" >> /etc/vconsole.conf

echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"
grub-install --target=i386-pc $1
grub-mkconfig -o /boot/grub/grub.cfg


echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
systemctl enable --now NetworkManager


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
useradd -m $USERNAME
passwd $USERNAME

usermod -aG wheel,audio,video,optical,disk,input,storage $USERNAME

sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers


