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
echo "INSTALLING AUR SOFTWARE"
echo "--------------------------------------"

cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm
cd ~
rm -rf yay

#export PATH=$PATH:~/.local/bin
#cp -r $HOME/ArchInstall/dotfiles/* $HOME/.config/

#source ArchInstall/packages.conf  #needed??
yay -S --noconfirm ${AUR_PKGS[@]}

exit