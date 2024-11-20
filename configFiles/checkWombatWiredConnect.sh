#!/bin/bash

# Check if static eth0 connection "wired_wombat" exists, if not, create it

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

#check if auto router eth0 connection "router_dhcp" exists, if not, create it
if nmcli connection show | grep "router_dhcp"; then
  echo "router_dhcp connection exists"
else
  echo "router_dhcp connection does not exists"
  echo "Creating now..."
  nmcli connection add type ethernet con-name router_dhcp ifname eth0 ipv4.method auto
  nmcli connection modify router_dhcp connection.autoconnect yes
  echo "router_dhcp created"
  echo "Rechecking if router_dhcp exists..."
  if nmcli connection show | grep "router_dhcp"; then
    echo "Created router_dhcp and exists!"
    sudo systemctl restart udhcpd.service
  else
    echo "Creating router_dhcp failed"
  fi
fi


while true; do
  # Detect Ethernet connection status
  if ethtool eth0 | grep -q "Link detected: yes"; then
    echo "Ethernet link detected"

    # Check for an existing IP address on eth0
    ETH_ADDRESS=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

    if [[ "$ETH_ADDRESS" == "192.168.124.1" ]]; then
    echo "Static IP detected; maintaining wired_wombat profile"
    # Do nothing or explicitly ensure wired_wombat is up
elif [[ "$ETH_ADDRESS" == "" ]]; then
    echo "No IP address; activating static profile"
    nmcli connection up wired_wombat
else
    echo "IP address detected; activating DHCP profile"
    nmcli connection down wired_wombat
    nmcli connection up router_dhcp
fi

  else
    echo "No Ethernet link detected; deactivating both profiles"
    nmcli connection down wired_wombat
  fi

  # Sleep for a few seconds to avoid excessive CPU usage
  sleep 5
done
