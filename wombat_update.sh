#!/bin/bash

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

# Make new wombat-os folder
mkdir /home/kipr/wombat-os || {
  echo "Failed to make new wombat-os directory during USB update"
  exit 1
}

temp_dir=$(mktemp -d)

# Find all .zip files under /media/kipr and unzip them into $temp_dir
zip_files=$(find /media/kipr/* -type f -name "*wombat-os*.zip")

echo "Found zip files: $zip_files"

if [ -n "$zip_files" ]; then
  for zip_file in $zip_files; do
    unzip -o "$zip_file" -d "$temp_dir" || {
      echo "Failed to unzip new wombat-os, restoring old version"
      sudo rm -R /home/kipr/wombat-os
      sudo mv /home/kipr/wombat-os-old /home/kipr/wombat-os
      echo "Old version restored"
      exit 1
    }
  done
else
  echo "No zip files found."
fi

# Find the extracted directory (only the first directory found)
extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -print -quit)
echo "Extracted dir: $extracted_dir"

# Check if a directory was found and if wombat_update.sh exists in it
if [ -z "$extracted_dir" ] || [ ! -f "$extracted_dir/updateFiles/wombat_update.sh" ]; then
  echo "No wombat_update.sh found in the zip file. Aborting."
  exit 1
fi

# Copy the contents of the extracted directory to /home/kipr/wombat-os
sudo cp -r "$extracted_dir"/* "/home/kipr/wombat-os" || {
  echo "Failed to copy files, restoring old version"
  sudo rm -R wombat-os
  sudo mv wombat-os-old wombat-os
  echo "Old version restored"
  exit 1
}

rm -rf "$temp_dir"

echo "Wombat-os updated, running update script"

# Change to updateFiles directory
cd /home/kipr/wombat-os/updateFiles || {
  echo "Failed to cd to updateFiles"
  exit 1
}

# Run update script

sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh || {
  echo "Update Failed"
  exit 1
}

