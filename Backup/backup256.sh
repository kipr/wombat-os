
#!/bin/bash

sudo mount /dev/sd?? /mnt
echo -e "Copying Files to USB Drive...\n"

sudo chmod -R 777 /home/root/Documents/KISS
sudo find /home/root/Documents/KISS -depth \( -name "* " -o -name "*)" -o -name "*?"  \) -execdir rename 's/[\s\)]+$//' {} \;
cp -r /home/root/Documents/KISS/* "/mnt/"
echo -e "Removing unwanted files... \n"

cd /mnt &&  rm -r bin && rm -r data && rm -r lib && rm -r src && rm -r include
echo "$PWD"
. ./modify_json.sh
sudo umount /dev/sd??


echo -e "\n \nAll projects backed up on flash drive! \n"
