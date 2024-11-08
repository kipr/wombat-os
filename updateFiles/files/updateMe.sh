#! /bin/bash

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
  if [[ $1 == *.zip && -f "$1/*/updateFiles/wombat_update.sh" ]]; then
    temp_dir=$(mktemp -d)

    # Unzip into a temporary directory
    unzip "$1" -d "$temp_dir" || {
      echo "Failed to unzip new wombat-os, restoring old version"
      sudo rm -R wombat-os
      sudo mv wombat-os-old wombat-os
      echo "Old version restored"
      exit 1
    }

    extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d)

    # Check if a directory was extracted
    if [[ -z "$extracted_dir" ]]; then
      echo "No directory found in the zip file. Aborting."
      exit 1
    fi

    # Copy the contents of the extracted directory to $HOME/wombat-os
    cp -r "$extracted_dir"/* "$HOME/wombat-os" || {
      echo "Failed to copy files, restoring old version"
      sudo rm -R wombat-os
      sudo mv wombat-os-old wombat-os
      echo "Old version restored"
      exit 1
    }

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
sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh || {
  echo "Update Failed"
  exit 1
}
