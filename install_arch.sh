#!/usr/bin/env bash

# check if legacy BIOS
if [ -d "/sys/firmware/efi/efivars" ]; then
    echo "This script is for legacy BIOS only!"
    exit 1
fi

echo "-------------------------------------------"
echo "- Setting up mirrors for optimal download -"
echo "-------------------------------------------"
pacman -Syy
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo "Please enter country abbreviation: (example US, PL, etc.)"
read COUNTRY
curl -s "https://archlinux.org/mirrorlist/?country="${COUNTRY^^}"&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 0 - > /etc/pacman.d/mirrorlist



echo -e "\nInstalling prereqs...\n$HR"
pacman -S --noconfirm gptfdisk btrfs-progs

echo "-------------------------------------------------"
echo "-------- select your disk to format -------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk: (example /dev/sda)"
read DISK
echo "--------------------------------------"
echo -e "\nFormatting disk...\n$HR"
echo "--------------------------------------"

# disk prep
# 1GB for boot
# 30GB for root
# rest for home
sfdisk ${DISK} << EOF
size=1GiB, type=83
size=30GiB, type=83
type=83
EOF

# make filesystems
echo -e "\nCreating Filesystems...\n$HR"

for x in {1..3}; do
    mkfs.ext4 "${DISK}${x}"
done

# mount target
mkdir /mnt/boot
mkdir /mnt/home
mount "${DISK}2" /mnt
mount "${DISK}1" /mnt/boot/
mount "${DISK}3" /mnt/home

echo "--------------------------------------"
echo "---- Arch Install on Main Drive ------"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware vim sudo grub --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

echo "--------------------------------------"
echo "--- Set Timezone, Clock and Locale ---"
echo "--------------------------------------"

echo "Please enter country name: (example Poland)"
read COUNTRY_NAME
ln -sf /usr/share/zoneinfo/${COUNTRY_NAME,,} /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen


echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"
grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg


echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager


echo "--------------------------------------"
echo "--      Set Password for Root       --"
echo "--------------------------------------"
echo "Enter password for root user: "
passwd root

exit
umount -R /mnt

echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
