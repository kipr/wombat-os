#! /bin/bash

echo "Starting Wombat Update"

# Check to see if static IP is live

# IP to check
STATIC_IP="192.168.186.3"

# Ping the IP and check if it is reachable
ping -c 1 $STATIC_IP &> /dev/null

if [ $? -eq 0 ]; then
    echo "Wombat is still in Ethernet Mode for Create 3. Please revert to Wifi mode and try updating again. Exiting script."
    exit 1
else
    echo "Wifi Mode check successful. Continuing script."
fi

# Change to home directory
cd /home/kipr || { echo "Failed to cd to /home/kipr"; exit 1; }

# Remove directory if it exists
WOMBAT_OS="wombat-os"
if [ -d $WOMBAT_OS ]; then
  sudo mv wombat-os wombat-os-old || { echo "Failed to rename wombat-os"; exit 1; }
fi

# Clone the repo
echo "Cloning wombat-os"
git clone https://github.com/kipr/wombat-os.git || { 
  echo "Failed to clone wombat-os, restoring old version";
  sudo rm -R wombat-os;
  sudo mv wombat-os-old wombat-os;
  echo "Old version restored";
  exit 1; 
}

# Change permissions of wombat-os
sudo chmod -R 777 /home/kipr/wombat-os || { echo "Failed to chmod wombat-os"; exit 1; }

# Change to updateFiles directory
cd /home/kipr/wombat-os/updateFiles || { echo "Failed to cd to updateFiles"; exit 1; }

echo "Update downloaded, running update script"

# Run update script
sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh && sudo rm -R wombat-os-old && echo "Update Complete" || { echo "Update Failed"; exit 1; }