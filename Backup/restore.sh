                                                                
#!/bin/bash

# Mount the USB drive
#sudo mount /dev/sd?? /mnt

# Define backup folder on the USB and restore location on the computer
BACKUP_FOLDER="Backed_Up_Projects"
USB_FOLDER="/mnt/$BACKUP_FOLDER"
RESTORE_FOLDER="/home/kipr/Documents/KISS"

# Check if the backup folder exists on the USB
if [ -d "$USB_FOLDER" ]; then
    echo "Found backup folder on USB: $USB_FOLDER"
    
    # Ensure the restore directory exists
    if [ ! -d "$RESTORE_FOLDER" ]; then
        echo "Creating restore folder: $RESTORE_FOLDER"
        mkdir -p "$RESTORE_FOLDER"
    fi

    # Copy files from USB backup folder to restore location
    echo -e "Restoring files to: $RESTORE_FOLDER\n"
    cp -r "$USB_FOLDER"/* "$RESTORE_FOLDER"

    echo -e "\nFiles successfully restored!"
else
    echo "Error: Backup folder not found on USB: $USB_FOLDER"
fi

# Unmount the USB drive
sudo umount /dev/sd??

echo -e "\nRestore process complete!\n"
