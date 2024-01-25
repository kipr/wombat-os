#!/bin/bash

case "$1" in
  eth)
    sudo cat /home/kipr/wombat-os/configFiles/create3_eth_ip.txt > /home/kipr/wombat-os/configFiles/create3_server_ip.txt || { echo "Failed to copy create3_eth_ip.txt"; exit 1;}
    sudo cat /home/kipr/wombat-os/configFiles/interfaces_eth.txt > /etc/network/interfaces || { echo "Failed to copy interfaces_eth.txt"; exit 1;}
    ;;
  wifi)
    sudo cat /home/kipr/wombat-os/configFiles/create3_wifi_ip.txt > /home/kipr/wombat-os/configFiles/create3_server_ip.txt || { echo "Failed to copy create3_wifi_ip.txt"; exit 1;}
    sudo cat /home/kipr/wombat-os/configFiles/interfaces_wifi.txt > /etc/network/interfaces || { echo "Failed to copy interfaces_wifi.txt"; exit 1;}
    ;;
  *)
    echo "Usage: $0 {eth|wifi}"
    exit 1
    ;;
esac

sudo systemctl stop create3_server.service
sleep 1
sudo reboot

exit 0
