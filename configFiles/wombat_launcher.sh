#!/bin/bash
#Bash script to launch harrogate web IDE and botui GUI
#created 23 May 2023

echo [WOMBAT] Launching harrogate server.js and botui GUI
export LD_LIBRARY_PATH=/usr/local/qt6/lib:/usr/local/lib


cd harrogate
sudo node server.js &
exec /home/kipr/wombat-os/configFiles/firstTimeScreen.sh &
sudo /usr/local/bin/botui &
sudo podman system prune
