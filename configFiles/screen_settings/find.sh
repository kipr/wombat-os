#!/bin/bash

if grep -q "InvertX" /etc/X11/xorg.conf.d/99-calibration.conf #if using inverted configs, need default
then 
        sudo cp /home/kipr/wombat-os/screen_settings/Default/99-calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf
        system("xrandr --output HDMI-1 --rotate normal")
        echo "Inverted settings found"

else #if using default configs, need inverted
        sudo cp /home/kipr/wombat-os/screen_settings/Inverted/99-calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf
        system("xrandr --output HDMI-1 --rotate inverted")
        echo "Default settings found"

fi
sleep 2

sudo reboot -h now