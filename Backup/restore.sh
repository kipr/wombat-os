#!/bin/bash

echo -e "Mounting USB drive... \n"
sudo mount /dev/sd?? /mnt
cd /mnt
echo -e "Moving projects from flash drive to the Controller... \n"
for dir in *; do
    if [ -d "$dir" ]; then
        echo "Possible User: $dir"
        cd "$dir"
        for subdir in *; do
            if [ -d "$subdir" ]; then
                echo "Possible Project: $subdir"
                source="$subdir/src"
                if [ -d "$source" ]; then
                    echo "$subdir project confirmed. Restoring Project..."
                    user="/home/kipr/Documents/KISS/$dir"
                    if [ ! -d "$user" ]; then
                        echo "User not found on Wombat. Creating $user"
                        mkdir "$user"
                    fi
                    cp -r "$subdir" "$user/$subdir"
                fi
            fi
        done
        cd ..
    fi
done

cd /home/kipr/Documents/KISS

sudo umount /dev/sd??
echo -e "\n \nAll programs restored with USB flash drive \n"
echo -e "If you do not see a user on the list create the user for their programs to show up \n"
