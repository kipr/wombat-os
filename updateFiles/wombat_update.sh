#!/bin/bash

FW_VERSION=30.1

echo "   "
echo "Starting Wombat Update #$FW_VERSION"
echo "..."

HOME=/home/kipr
cd $HOME/wombat-os/updateFiles

###############################
#
# update boot files
#
###############################

#remount root filesystem as read write
mount -o remount,rw /


###############################
#
# update packages
#
###############################

# harrogate
echo "Updating harrogate..."
sudo rm -r /home/kipr/harrogate
sudo tar -C /home/kipr -zxvf pkgs/harrogate.tar.gz
sudo chmod 777 /home/kipr/harrogate
cd /home/kipr/harrogate
sudo npm install
sudo killall node
sudo gulp &
cd $HOME/wombat-os/updateFiles

# libkar
echo "Updating libkar..."
sudo dpkg -i pkgs/libkar.deb

# pcompiler
echo "Updating pcompiler..."
sudo dpkg -i pkgs/pcompiler.deb

# libwallaby
echo "Updating libwallaby..."
sudo dpkg -i pkgs/kipr.deb

# botui
echo "Updating botui..."
sudo rm -r /usr/local/bin/botui
sudo dpkg -i pkgs/botui.deb

cd $HOME

###############################
#
# edit misc files
#
###############################

# Copy Wombat Launcher to home directory
TARGET=wombat-os/configFiles/wombat_launcher.sh
echo "Copying the launcher"
cp $TARGET $HOME

#Adding Default Programs
echo "Checking for Default User"
TARGET=/home/kipr/wombat-os/updateFiles/files/'Default User'
if [ ! -d "/home/kipr/Documents/KISS/Default User/" ]; then
    mkdir /home/kipr/Documents/KISS/'Default User'
fi
echo "Adding Default Programs"
sudo cp -r $TARGET /home/kipr/Documents/KISS/'Default User'

echo "Flashing the Processor"
cd /home/kipr/wombat-os/flashFiles
sudo chmod +x wallaby_flash wallaby_get_id.sh wallaby_set_serial.sh
sudo ./wallaby_flash



###############################
#
# sync and reboot
#
###############################
echo "Finished Wombat Update #$FW_VERSION"
echo "Rebooting..."
sleep 3
reboot
