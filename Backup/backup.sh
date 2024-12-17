#!/bin/bash

#sudo mount /dev/sd?? /mnt

BACKUP_FOLDER="Backed_Up_Projects"
USB_FOLDER="/mnt/$BACKUP_FOLDER"

if [ ! -d "$USB_FOLDER" ]; then
    echo "Creating backup folder in USB root: $USB_FOLDER"
    mkdir -p "$USB_FOLDER"
else
    echo "Backup folder already exists: $USB_FOLDER"
fi

echo -e "Copying Users and Projects to USB Drive...\n"

cp -r /home/kipr/Documents/KISS/* "USB_FOLDER"

sudo umount /dev/sd??

echo -e "\n Valid projects backed up on flash drive! \n"
