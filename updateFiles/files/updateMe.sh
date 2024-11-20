#! /bin/bash

#######################################################################################################
#																								   																		                #
#		Author: Erin Harrington, Tim Corbly																																#
#		Date: 2024-11-19						                                                                		  #
#   Arguments: None for ethernet update, .zip file path for USB update																#																	    #								
#		Description: Update file looked for by Botui when running USB or ethernet update                  #
#																																																			#							
#######################################################################################################


echo "Starting Wombat Update"

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
  echo "Old wombat-os removed"
fi

# Remove directory if it exists
WOMBAT_OS="wombat-os"
if [ -d $WOMBAT_OS ]; then
  sudo mv wombat-os wombat-os-old || {
    echo "Failed to rename wombat-os"
    exit 1
  }
fi

# if an string argument was passed -> USB update
if [ -n "$1" ]; then

  #check if the argument is a .zip file containing updateFiles/wombat_update.sh
  if [[ $1 == *.zip ]]; then
    temp_dir=$(mktemp -d)

    # Unzip into a temporary directory
    unzip "$1" -d "$temp_dir" || {
      echo "Failed to unzip new wombat-os, restoring old version"
      sudo rm -R wombat-os
      sudo mv wombat-os-old wombat-os
      echo "Old version restored"
      exit 1
    }
    # Find the extracted directory (only the first directory found)
    extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -print -quit)

    # Check if a directory was found and if wombat_update.sh exists in it
    if [[ -z "$extracted_dir" || ! -f "$extracted_dir/updateFiles/wombat_update.sh" ]]; then
      echo "No wombat_update.sh found in the zip file. Aborting."
      exit 1
    fi

    # Make new wombat-os folder
    mkdir /home/kipr/wombat-os || {
      echo "Failed to make new wombat-os directory during USB update"
      exit 1
    }

    # Copy the contents of the extracted directory to /home/kipr/wombat-os
    cp -r "$extracted_dir"/* "/home/kipr/wombat-os" || {
      echo "Failed to copy files, restoring old version"
      sudo rm -R wombat-os
      sudo mv wombat-os-old wombat-os
      echo "Old version restored"
      exit 1
    }

    echo ".zip file extracted to /home/kipr/wombat-os"

    # Clean up the temporary directory
    rm -rf "$temp_dir"
  else
    echo "Invalid input: The provided argument must be a .zip file containing updateFiles/wombat_update.sh"
    exit 1

  fi
#No argument was passed -> ethernet update
else
  # Clone the repo
  echo "Cloning wombat-os"
  git clone https://github.com/kipr/wombat-os.git || {
    echo "Failed to clone wombat-os, restoring old version"
    sudo rm -R wombat-os
    sudo mv wombat-os-old wombat-os
    echo "Old version restored"
    exit 1
  }
fi

# Change permissions of wombat-os
sudo chmod -R 777 /home/kipr/wombat-os || {
  echo "Failed to chmod wombat-os"
  exit 1
}

# Change to updateFiles directory
cd /home/kipr/wombat-os/updateFiles || {
  echo "Failed to cd to updateFiles"
  exit 1
}

echo "Update downloaded, running update script"

# Run update script
sudo chmod u+x wombat_update.sh && sudo /home/kipr/wombat-os/updateFiles/wombat_update.sh || {
  echo "Update Failed"
  exit 1
}
