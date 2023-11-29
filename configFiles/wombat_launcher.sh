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
sudo podman run -dt --rm --net=host --env IP=192.168.125.1 --name create3_server docker.io/kipradmin/create3_docker
