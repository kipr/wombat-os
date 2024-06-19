#! /bin/bash

echo "Starting Wombat Update"

# Check to see if static IP is live

# File and IP to check
STATIC_IP="192.168.186.3"
FILE_TO_SEARCH="/home/kipr/wombat-os/configFiles/create3_server_ip.txt"

# Use grep to search for the IP address in the file
if grep -q "$STATIC_IP" "$FILE_TO_SEARCH"; then
    echo "Wombat is still in Ethernet Mode for Create 3. Please revert to Wifi mode and try updating again. Exiting script."
    exit 0
else
    echo "Wifi Mode check successful. Continuing script."
fi

# Change to home directory
cd /home/kipr || { echo "Failed to cd to /home/kipr"; exit 1; }

# Remove old wombat-os if it exists
if [ -d "wombat-os-old" ]; then
  sudo rm -R wombat-os-old || { echo "Failed to remove old wombat-os"; exit 1; }
fi

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
sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh || { echo "Update Failed"; exit 1; }