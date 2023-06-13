#!/bin/bash

if grep -q "InvertY" /etc/X11/xorg.conf.d/99-calibration.conf #if using inverted configs, need default
then 
        sudo cp /home/kipr/wombat-os/screen_settings/Default/99-calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf
        echo "Inverted settings found"

else #if using default configs, need inverted
        sudo cp /home/kipr/wombat-os/screen_settings/Inverted/99-calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf
        echo "Default settings found"

fi
sleep 1

sudo reboot -h now