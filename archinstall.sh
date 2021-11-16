#!/bin/bash
#-----------------------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║      
#  ███████║██████╔╝██║     ███████║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║      
#  ██╔══██║██╔══██╗██║     ██╔══██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║      
#  ██║  ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗ 
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝ 
#-----------------------------------------------------------------------------------------

#SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

bash 0-preinstall.sh
arch-chroot /mnt /ArchInstall/1-setup.sh
source /mnt/ArchInstall/install.conf
#arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchInstall/2-user.sh
arch-chroot /mnt /usr/bin/runuser -u $username -- /ArchInstall/2-user.sh
arch-chroot /mnt /ArchInstall/3-post-setup.sh

rm -rf /mnt/ArchInstall
umount -R /mnt

echo "###############################################################################"
echo "# Install Complete - Remove Install Media and Reboot"
echo "###############################################################################"