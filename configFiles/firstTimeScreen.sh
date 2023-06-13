#!/bin/bash

if grep -q "inverted" /etc/X11/xorg.conf.d/99-calibration.conf
then
	xrandr --output HDMI-1 --rotate inverted #invert screen
else
	xrandr --output HDMI-1 --rotate normal #normal screen


fi
sleep 1
