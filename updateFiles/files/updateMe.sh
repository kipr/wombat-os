#! /bin/bash

echo "Starting Wombat Update"

# Change to home directory
cd /home/kipr || { echo "Failed to cd to /home/kipr"; exit 1; }

# Remove directory if it exists
wombat-os="wombat-os"
if [ -d "$wombat-os" ]; then
  sudo rm -R wombat-os || { echo "Failed to rm wombat-os"; exit 1; }
fi

# Clone the repo
echo "Cloning wombat-os"
git clone https://github.com/kipr/wombat-os.git || { echo "Failed to clone wombat-os"; exit 1; }

# Change permissions of wombat-os
sudo chmod -R 777 /home/kipr/wombat-os || { echo "Failed to chmod wombat-os"; exit 1; }

# Change to updateFiles directory
cd /home/kipr/wombat-os/updateFiles || { echo "Failed to cd to updateFiles"; exit 1; }

echo "Update downloaded, running update script"

# Run update script
sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh && echo "Update Complete" || { echo "Update Failed"; exit 1; }