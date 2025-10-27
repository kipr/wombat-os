#!/bin/bash
shopt -s nullglob
LOGFILE="/home/kipr/voldigate_update.log"

sudo touch "$LOGFILE"
sudo chmod 666 "$LOGFILE"

>"$LOGFILE"

exec &> >(tee -a "$LOGFILE")

HOME_DIR="/home/kipr/Documents/KISS"
CLASSROOM_JSON_PATH=$HOME_DIR/classrooms/classrooms.json
SCRIPT_DIR="$(dirname "$0")"

#Give write permissions to all of HOME_DIR
sudo chmod 777 -R $HOME_DIR

echo "Beginning Voldigate IDE update..."

###############################
# Remove unnecessary packages #
###############################

#Remove harrogate

if [ -d "/home/kipr/harrogate" ]; then
  sudo rm -rf /home/kipr/harrogate
  echo "Harrogate removed!"
fi


sudo apt-get remove --purge \
  libboost1.74-dev \
  pypy \
  firmware-atheros \
  firmware-libertas \
  firmware-misc-nonfree \
  containernetworking-plugins \
  vlc-l10n \
  realvnc-vnc-server \
  pocketsphinx-en-us \
  git \
  podman \
  libxcb-doc -y

sudo apt autoremove --purge -y

sudo rm -rf /var/lib/containers/*
sudo rm -rf /var/lib/apt/lists/*

# Remove Create Test if present
if [ -d "/home/kipr/Documents/Default User/Create Test" ]; then
  sudo rm -rf "/home/kipr/Documents/Default User/Create Test"
  echo "Create Test removed!"
fi

echo "Reorganizing users.json into new voldigate users.json structure..."

cd "$SCRIPT_DIR"

bash ./reorganizeUsersJson.sh

if [ -f "$CLASSROOM_JSON_PATH" ]; then
  echo "classrooms.json exists"
else
  echo "Creating classrooms.json..."
  mkdir "$HOME_DIR"/classrooms
  echo "{}" >"$CLASSROOM_JSON_PATH"
fi

#Check if Wombat has yarn >= v1.22.22, remove cmdtest if present
if dpkg -l | grep -q "^ii  cmdtest "; then
  echo "cmdtest is installed, removing..."
  sudo apt remove -y cmdtest
else
  echo "cmdtest is not installed."
fi


#Kill previously used port 8888
sudo fuser -k 8888/tcp


#########################
# Install Voldigate IDE #
#########################

cp ../pkgs/voldigate-slim-wombat.deb /home/kipr
cd /home/kipr
sudo dpkg -i voldigate-slim-wombat.deb
