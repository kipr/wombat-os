#!/bin/bash

#######################################################################################################
#                                                                                                     #
#       Authors: Tim Corbly, Erin Harrington, Thomas Wells                                            #
#       Date: 2025-09-24                                                                              #
#       Description: True Wombat update file in versions >= 31.0.0                                    #
#                                                                                                     #
#######################################################################################################

HOME=/home/kipr
CURRENT_FW_VERSION=$(cat "$HOME/wombat-os/configFiles/board_fw_version.txt")
NEW_FW_VERSION=$(cat ../configFiles/board_fw_version.txt)

echo "   "
echo "Starting Wombat Update from (wombat-os/updateFiles/wombat_update.sh) #$CURRENT_FW_VERSION to #$NEW_FW_VERSION"
echo "..."

###############################
#
# Check for Current FW Version
#
###############################

# Check if board_fw_version.txt exists
if [ ! -f /usr/share/kipr/board_fw_version.txt ]; then
	echo "Your version is too old to update. Please reflash your SD card."
	exit 1
fi

# Cleanup for space
echo "Cleaning up space..."
sudo apt-get remove --purge \
	libboost1.74-dev \
	pypy \
	firmware-atheros \
	firmware-libertas \
	firmware-misc-nonfree \
	containernetworking-plugins \
	vlc-l10n \
	realvnc-vnc-server \
	pocketsphinx-en-us \
	git \
	podman \
	libxcb-doc -y

sudo apt autoremove --purge -y

sudo rm -rf /var/lib/containers/* /var/lib/apt/lists/* /var/cache/apt/archives/* /home/kipr/Bookshelf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

###############################
#
# Move update files
#
###############################

# Change to updateFiles directory and copy updateMe.sh to home directory
cd $HOME/wombat-os/updateFiles
cp files/updateMe.sh $HOME
sudo chmod u+x $HOME/updateMe.sh

# Change to configFiles directory and copy board_fw_version.txt to kipr share directory
cd $HOME/wombat-os/configFiles
if [ ! -d /usr/share/kipr ]; then
	sudo mkdir /usr/share/kipr
fi

sudo cp board_fw_version.txt /usr/share/kipr/
sudo cp board_copyright_year.txt /usr/share/kipr/
sudo cp journald.conf /etc/systemd/journald.conf
sudo cat interfaces_wifi.txt >/etc/network/interfaces

# Copy new Wombat picture over old one
sudo cp $HOME/wombat-os/wombat.jpg /usr/share/rpd-wallpaper/wombat.jpg

# Set up systemd services as replacement for old wombat_launcher
sudo cp balancer.service checkWiredConnection.service botui.service first-time-screen.service voldigate.service wombat.target /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable checkWiredConnection.service wombat.target

# Give execute permissions
sudo chmod +x $HOME/wombat-os/configFiles/checkWombatWiredConnection_temp.sh $HOME/wombat-os/configFiles/balancer.sh

# Remove old xdg-autostart file
sudo rm /etc/xdg/autostart/botui.desktop
sudo rm /home/kipr/wombat_launcher.sh

###############################
#
# update boot files
#
###############################

#remount root filesystem as read write
sudo mount -o remount,rw /

###############################
#
# update packages
#
###############################

# voldigate
cd $HOME/wombat-os/updateFiles
bash ./files/voldigate_update.sh

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

#udhcpd
echo "Updating udhcpd..."
sudo dpkg -i pkgs/installs/udhcpd_arm64.deb

# gpiod
echo "Installing gpiod"
sudo dpkg -i pkgs/installs/libgpiod2_1.6.2-1_arm64.deb
sudo dpkg -i pkgs/installs/libgpiod-dev_1.6.2-1_arm64.deb
sudo dpkg -i pkgs/installs/gpiod_1.6.2-1_arm64.deb

cd $HOME

###############################
#
# edit misc files
#
###############################

# Copy udhcpd files to Wombat
echo "Copying udhcpd files..."
sudo cp $HOME/wombat-os/configFiles/udhcpd.conf /etc/udhcpd.conf
sudo cp $HOME/wombat-os/configFiles/udhcpd /etc/default/udhcpd

#Remove Create 3 Capn'Proto files from /
echo "Removing Create 3 Capn'Proto files if present..."
capnProtoFiles=$(find / -type f -iname "*capn*" 2>/dev/null)
if [ -n "$capnProtoFiles" ]; then
	echo "Found files to delete:"
	echo "$capnProtoFiles"
	find / -type f -iname "*capn*" -exec rm -f {} \; 2>/dev/null
	echo "Files deleted."
else
	echo "No files matching '*capn*' were found."
fi

#Remove Create 3 deb file if present
echo "Removing Create 3 .deb file if present..."
create3Deb=$(find /home/kipr -type f -iname "create3-0.1.0-Linux.deb" 2>/dev/null)
if [ -n "$create3Deb" ]; then
	echo "Removing Create 3 deb file"
	sudo rm /home/kipr/create3-0.1.0-Linux.deb
fi

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
sudo chmod +x *
sudo ./wallaby_flash

###############################
#
# sync and reboot
#
###############################
echo "Finished Wombat Update #$FW_VERSION"

# Remove old wombat-os if it exists
cd /home/kipr
if [ -d "wombat-os-old" ]; then
	sudo rm -R wombat-os-old || {
		echo "Failed to remove old wombat-os"
		exit 1
	}
fi

sudo chown -R kipr:kipr /home/kipr/Documents

echo "Rebooting..."

echo "Update Complete" && sudo reboot || {
	echo "Could not reboot"
	exit 1
}
