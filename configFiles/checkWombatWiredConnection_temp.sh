#!/bin/bash

WIRED_CONN="wired_wombat"
ETH_IF="eth0"
STATIC_IP="192.168.124.1/24"
DHCP_SERVICE="udhcpd"

# Ensure wired connection profile exists
if ! nmcli connection show | grep -q "$WIRED_CONN"; then
    echo "$(date) - Creating wired connection profile..."
    nmcli connection add type ethernet con-name "$WIRED_CONN" ifname "$ETH_IF" ipv4.method manual ipv4.addresses "$STATIC_IP" ipv4.gateway "${STATIC_IP%/*}"
    nmcli connection modify "$WIRED_CONN" connection.autoconnect no
fi

# Check if Ethernet cable is plugged in
if ethtool "$ETH_IF" 2>/dev/null | grep -q "Link detected: yes"; then
    echo "$(date) - Ethernet detected, bringing up $WIRED_CONN"

    # Bring up wired connection
    nmcli connection up "$WIRED_CONN"

    # Wait until the interface has the correct IP
    while ! ip -4 addr show "$ETH_IF" | grep -q "${STATIC_IP%/*}"; do
        echo "$(date) - Waiting for $ETH_IF to get IP $STATIC_IP..."
        sleep 1
    done

    echo "$(date) - $ETH_IF is up with IP $STATIC_IP, starting DHCP..."
    sudo systemctl restart "$DHCP_SERVICE"

else
    echo "$(date) - Ethernet not detected, bringing down $WIRED_CONN"

    # Bring down wired connection
    nmcli connection down "$WIRED_CONN"

    # Stop DHCP server
    sudo systemctl stop "$DHCP_SERVICE"
fi

