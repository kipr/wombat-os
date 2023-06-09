#!/bin/bash

FW_VERSION=30.1.1

echo "   "
echo "Starting Wombat Update #$FW_VERSION"
echo "..."

HOME=/home/kipr
cd $HOME/wombat-os/updateFiles
cp files/updateMe.sh $HOME
sudo chmod u+x $HOME/updateMe.sh

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
echo "Installing harrogate dependencies..."
npm install browserfy
npm install
sudo npm install -g gulp@4 gulp-cli
echo "Killing any running harrogate processes..."
sudo killall node
echo "Starting harrogate..."
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
sudo cp "$TARGET" "$HOME"
sudo chmod 777 "$HOME/wombat_launcher.sh"

#Adding Default Programs
echo "Checking for Default User"
TARGET="/home/kipr/wombat-os/updateFiles/files/Wombat Factory Test"
CP_TARGET="/home/kipr/Documents/KISS/Default User/"
if [ ! -d "$CP_TARGET" ]; then
    mkdir "$CP_TARGET" || echo "Failed to make Default User"
else 
    echo "Default User already exists"
fi
echo "Adding Default Programs"
sudo cp -R "$TARGET" "$CP_TARGET" || echo "Failed to copy Default Programs"
sudo chmod -R 777 "$CP_TARGET" || echo "Failed to chmod Default Programs"

echo "Flashing the Processor"
cd /home/kipr/wombat-os/flashFiles
sudo chmod +x wallaby_flash wallaby_get_id.sh wallaby_set_serial.sh
sudo ./wallaby_flash

echo "Letting harrogate finish gulping"
sleep 70


###############################
#
# sync and reboot
#
###############################
echo "Finished Wombat Update #$FW_VERSION"
echo "Rebooting..."
sleep 3
reboot
