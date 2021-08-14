#!/bin/sh

# check if legacy BIOS
if [ -d "/sys/firmware/efi/efivars" ]; then
    echo "This script is for legacy BIOS only!"
    exit 1
fi

echo "-------------------------------------------"
echo "- Setting up mirrors for optimal download -"
echo "-------------------------------------------"
pacman -Syy
timedatectl --no-ask-password set-timezone Europe/Warsaw
timedatectl --no-ask-password set-ntp 1
pacman -S --noconfirm pacman-contrib
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://archlinux.org/mirrorlist/?country=PL&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 0 - > /etc/pacman.d/mirrorlist


echo "-------------------------------------------------"
echo "-------- select your disk to format -------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk: (example /dev/sda)"
read DISK
echo "--------------------------------------"
echo -e "\nFormatting disk...\n"
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
echo -e "\nCreating Filesystems...\n"

for x in {1..3}; do
    yes | mkfs.ext4 "${DISK}${x}"
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
pacstrap /mnt base linux linux-firmware --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
cp /root/auto-arch/setup-arch.sh /mnt/home/
arch-chroot /mnt sh /home/setup-arch.sh $DISK

# finally
rm /mnt/home/setup-arch.sh
umount -R /mnt

echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
