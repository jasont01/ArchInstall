#!/usr/bin/env bash
#-----------------------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║      
#  ███████║██████╔╝██║     ███████║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║      
#  ██╔══██║██╔══██╗██║     ██╔══██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║      
#  ██║  ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗ 
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝ 
#-----------------------------------------------------------------------------------------

echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S --noconfirm --needed networkmanager dhcpcd
#systemctl enable --now NetworkManager

#echo "-------------------------------------------------"
#echo "Setting up mirrors for optimal download          "
#echo "-------------------------------------------------"
#pacman -S --noconfirm pacman-contrib curl reflector rsync
##??????????????

nc=$(grep -c ^processor /proc/cpuinfo)
echo "-------------------------------------------------"
echo " $nc cores detected."
echo "-------------------------------------------------"
#TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
#if [[  $TOTALMEM -gt 8000000 ]]; then
echo "Updating makeflags..."
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
echo "Updating compression settings..."
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
#fi

echo "-------------------------------------------------"
echo "       Setup Language to US and set locale       "
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone America/New_York
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"

# Set keymaps
localectl --no-ask-password set-keymap us

#Add parallel downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

#Enable multilib
echo "-------------------------------------------------"
echo " Enable Multilib?"
echo "-------------------------------------------------"
read -p " [y/n] " response
case $response in
 [yY]* )
    echo "Enabling Multilib"
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm
    MULTILIB=true
    ;;
  [nN]* )
    MULTILIB=false
    ;;
  esac
fi

echo "-------------------------------------------------"
echo " Installing Packages"
echo "-------------------------------------------------"

source packages.conf

pacman -S --noconfirm --needed ${PKGS[@]}

# processor microcode
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac

# Install Graphics Drivers
pacman -S --noconfirm mesa
if $MULTILIB; then
  pacman -S --noconfirm --needed lib32-mesa
fi

# Nvidia Graphics
if lspci | grep -E "NVIDIA|GeForce"; then
  echo "-------------------------------------------------"
  echo " NVIDIA GPU Detected."
  echo " Install drivers?"
  echo "-------------------------------------------------"
  read -p " [y/n] " response
  case $response in
    [yY]* )
      echo "Installing NVIDIA drivers"
      pacman -S --noconfirm nvidia nvidia-utils
      if $MULTILIB; then
        pacman -S --noconfirm lib32-nvidia-utils
      fi
      ;;
    [nN]* )
      echo "Skipping NVIDIA drivers"
      ;;
  esac
fi

# AMD Graphics
if lspci | grep -E "Radeon"; then
  pacman -S --noconfirm --needed xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau
  if $MULTILIB; then
    pacman -S --noconfirm --needed lib32-vulkan-radeon lib32-libva-mesa-driver lib32-mesa-vdpau
  fi
fi

# Intel Graphics
if lspci | grep -E "Integrated Graphics Controller"; then
  pacman -S --noconfirm --needed xf86-video-intel vulkan-intel libva-mesa-driver mesa-vdpau
  if $MULTILIB; then
    pacman -S --noconfirm --needed lib32-vulkan-intel lib32-libva-mesa-driver lib32-mesa-vdpau
  fi
fi

source /ArchInstall/install.conf

echo "-------------------------------------------------"
echo " Install Bootloader"
echo "-------------------------------------------------"
bootctl install

cat <<EOF > /boot/loader/loader.conf
default arch
timeout 0
EOF

cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=${ROOT} rw
EOF

echo "-------------------------------------------------"
echo " Set Root Password"
echo "-------------------------------------------------"
passwd

echo "-------------------------------------------------"
echo " Setup Admin User"
echo "-------------------------------------------------"

if [ -z "$username" ]; then
  read -p "Enter username for admin user: " username
fi
echo "username=$username" >> /ArchInstall/install.conf

useradd -m -G wheel,libvirt -s /bin/bash $username
passwd $username

#cp -R /ArchInstall /home/$username/
#chown -R $username: /home/$username/ArchInstall
if [ -z "$hostname" ]; then
  read -p "Enter hostname: " hostname
fi
echo $hostname > /etc/hostname

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
