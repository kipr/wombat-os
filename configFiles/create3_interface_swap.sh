#!/bin/bash

case "$1" in
  eth)
    cat create3_eth_ip.txt > create3_server_ip.txt
    cat interfaces_eth.txt > /etc/network/interfaces
    ;;
  wifi)
    cat create3_wifi_ip.txt > create3_server_ip.txt
    cat interfaces_wifi.txt > /etc/network/interfaces
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
