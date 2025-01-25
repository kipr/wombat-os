#!/bin/bash

#######################################################################################################
#																								   																		                #
#		Author: Tim Corbly, Erin Harrington																																#
#		Date: 2025-01-24																																							    #								
#		Description: Dummy Wombat update file for versions <= 30.3.0                                      #
#																																																			#							
#######################################################################################################

HOME=/home/kipr
CURRENT_FW_VERSION=$(cat "$HOME/wombat-os/configFiles/board_fw_version.txt")
NEW_FW_VERSION=$(cat configFiles/board_fw_version.txt)

echo "   "
echo "Starting Wombat Update (wombat-os/wombat_update.sh) from #$CURRENT_FW_VERSION to #$NEW_FW_VERSION"
echo "..."

# Change to home directory
cd /home/kipr || {
  echo "Failed to cd to /home/kipr"
  exit 1
}

# Remove old wombat-os if it exists
if [ -d "wombat-os-old" ]; then
  sudo rm -R wombat-os-old || {
    echo "Failed to remove old wombat-os"
    exit 1
  }
fi

# Change wombat-os to wombat-os-old
WOMBAT_OS="wombat-os"
if [ -d $WOMBAT_OS ]; then
  sudo mv wombat-os wombat-os-old || {
    echo "Failed to rename wombat-os"
    exit 1
  }
fi


WOMBAT_OS="wombat-os"
WOMBAT_OS_NEW=$(find /media/kipr/*/wombat-os-* -maxdepth 0 -type d -name 'wombat-os-*' 2>/dev/null | \
awk -F'wombat-os-' '
{
    split($2, ver, "."); 
    if (ver[1] >= 31 && ver[2] >= 0 && ver[3] >= 0) 
        print $0
}')

# Check if wombat-os-31.0.0 or greater directory exists
if [ -z "$WOMBAT_OS_NEW" ]; then
  echo "No wombat-os-31.0.0 or higher directory found. If you downloaded wombat-os v31.0.0 or higher, please make sure that the file has been extracted to your flash drive and that there is not a duplicate folder inside the extracted folder."
  exit 1
fi

# Check if only one directory was found
if [ $(echo "$WOMBAT_OS_NEW" | wc -l) -ne 1 ]; then
  echo "Multiple matches found for wombat-os-31Update. Please specify the correct path."
  exit 1
fi

# Copy the new directory to /home/kipr and rename it
sudo cp -r "$WOMBAT_OS_NEW" /home/kipr/"$WOMBAT_OS" || {
  echo "Failed to copy $WOMBAT_OS_NEW to /home/kipr/$WOMBAT_OS"
  if [ -d "${WOMBAT_OS}-old" ]; then
    sudo mv "${WOMBAT_OS}-old" "$WOMBAT_OS" # Restore the original directory if copy fails
  fi
  exit 1
}


echo "Wombat-os updated, running update script"

# Change to updateFiles directory
cd /home/kipr/wombat-os/updateFiles || {
  echo "Failed to cd to updateFiles"
  exit 1
}

# Run update script

sudo chmod u+x wombat_update.sh && sudo /home/kipr/wombat-os/updateFiles/wombat_update.sh || {
  echo "Update Failed"
  exit 1
}
