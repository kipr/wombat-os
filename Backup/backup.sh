#!/bin/bash

sudo mount /dev/sd?? /mnt
echo -e "Copying Files to USB Drive...\n" 

cp -r /home/kipr/Documents/KISS/* /mnt

sudo umount /dev/sd??


echo -e "\n \nAll projects backed up on flash drive! \n"
