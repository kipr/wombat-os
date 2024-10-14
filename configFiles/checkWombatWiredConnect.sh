#!/bin/bash

#check if static eth0 connection "wired_wombat" exists, if not, create it

if nmcli connection show | grep "wired_wombat"; then
  echo "wired_wombat connection exists"
else
  echo "wired_wombat connection does not exists"
  echo "Creating now..."
  nmcli connection add type ethernet con-name wired_wombat ifname eth0 ipv4.method manual ipv4.addresses 192.168.124.1/24 ipv4.gateway 192.168.124.1
  nmcli connection modify wired_wombat connection.autoconnect no
  echo "wired_wombat created"
  echo "Rechecking if wired_wombat exists..."
  if nmcli connection show | grep "wired_wombat"; then
    echo "Created wired_wombat and exists!"
    sudo systemctl restart udhcpd.service
  else
    echo "Creating wired_wombat failed"
  fi
fi

#remove any static IPs that are up
if nmcli connection show --active | grep wired_wombat; then
  echo "Connection wired_wombat is up"
  echo "Closing down wired_wombat"
  nmcli connection down wired_wombat

else
  echo "Connection wired_wombat is down"
fi

while true; do # (controller on)

  if ethtool eth0 | grep -q "Link detected: yes"; then #Ethernet cable connected
    echo "Ethernet link detected"

    #check for auto IP assingment
    ETH_ADDRESS=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo $ETH_ADDRESS

    #Computer
    if [[ "$ETH_ADDRESS" == "" ]]; then
      echo "Connected ethernet to computer"
      nmcli connection up wired_wombat
      while true; do
        if ethtool eth0 | grep -q "Link detected: yes"; then
          echo "Ethernet cable is connected, connected to computer"
          if ping -c 1 192.168.124.2 >/dev/null; then
            echo "Connection to 192.168.124.2 (computer) is solid"
          else
            echo "Failed to connect to 192.168.124.2 (computer)"
            echo "Restarting udhcpd.service..."
            sudo systemctl restart udhcpd.service
          fi
        else
          echo "Ethernet cable is not connected"
          break
        fi
        sleep 3

      done
      nmcli connection down wired_wombat

      #Router

    elif [[ "$ETH_ADDRESS" != "192.168.124.1" ]]; then
      echo "Connected ethernet to router"
      while true; do
        if ethtool eth0 | grep -q "Link detected: yes"; then
          echo "Ethernet cable is connected"
        else
          echo "Ethernet cable is not connected"
          break
        fi
        sleep 3
      done
    fi

  else
    #Ethernet cable not detected
    echo "No Ethernet link detected"

  fi

  sleep 3
done
