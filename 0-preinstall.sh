#!/usr/bin/env bash

echo "-----------------------------------------------------------------------------------------"
echo "   █████╗ ██████╗  ██████╗██╗  ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      "
echo "  ██╔══██╗██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║      "
echo "  ███████║██████╔╝██║     ███████║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║      "
echo "  ██╔══██║██╔══██╗██║     ██╔══██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║      "
echo "  ██║  ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗ "
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝ "
echo "-----------------------------------------------------------------------------------------"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
timedatectl set-ntp true

sed -i 's/^#Para/Para/' /etc/pacman.conf # Enable Parallel Downloads

echo "------------------------------------------"
echo " Installing prereqs..."
echo "------------------------------------------"

pacman -S --noconfirm reflector pacman-contrib rsync

echo "------------------------------------------"
echo " Finding fastest mirrors..."
echo "------------------------------------------"

reflector \
--age 24 \
--country US \
--fastest 5 \
--latest 20 \
--sort rate \
--save /etc/pacman.d/mirrorlist

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in

y|Y|yes|Yes|YES)
echo "--------------------------------------"
echo " Formatting disk..."
echo "--------------------------------------"

# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+512M --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK} # partition 1 (UEFI Boot Partition)
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK} # partition 2 (Root), default start, remaining
# if [[ ! -d "/sys/firmware/efi" ]]; then
#     sgdisk -A 1:set:2 ${DISK}
# fi

# make filesystems
echo "--------------------------------------"
echo " Creating Filesystems..."
echo "--------------------------------------"

if [[ ${DISK} =~ "nvme" ]]; then
  BOOT="${DISK}p1"
  ROOT="${DISK}p2"
else
  BOOT="${DISK}1"
  ROOT="${DISK}2"
fi

echo "ROOT=$ROOT" >> ${SCRIPT_DIR}/install.conf

mkfs.vfat -F32 -n "EFIBOOT" ${BOOT}
mkfs.ext4 -L "ROOT" ${ROOT}
mount -t ext4 ${ROOT} /mnt
mkdir /mnt/boot
mount -t vfat ${BOOT} /mnt/boot

#mkfs.btrfs -L "HOME" "${DISK}p2" -f
#mount -t btrfs "${DISK}p2" /mnt
#ls /mnt | xargs btrfs subvolume delete
#btrfs subvolume create /mnt/@
#umount /mnt
;;

*)
echo "--------------------------------------"
echo " Install Aborted..."
echo "--------------------------------------"
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
;;
esac

echo "--------------------------------------"
echo " Installing Base System"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware sudo
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/ArchInstall
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

#echo "--------------------------------------"
#echo " Installing Bootloader"
#echo "--------------------------------------"

