#!/bin/bash

LOGFILE="/home/kipr/voldigate_update.log"

sudo touch "$LOGFILE"
sudo chmod 666 "$LOGFILE"

>"$LOGFILE"

exec &> >(tee -a "$LOGFILE")

OLD_USER_JSON="/home/kipr/Documents/KISS/users.json"
NEW_USER_JSON="/home/kipr/Documents/KISS/newUsers.json"
HOME_DIR="/home/kipr/Documents/KISS"
SCRIPT_DIR="$(dirname "$0")"
JQ="$SCRIPT_DIR/pkgs/jq-linux64"

#Need to transform old users.json style into new voldigate users.json style


#Get all directories stored in /home/kipr/Documents/KISS - Users
for dir in "$HOME_DIR"/*; do
    if [ -d "$dir" ]; then
        echo "Directory: $dir"
        userName=$(basename "$dir")
        userPath_array+=(${dir})
        user_array+=(${userName})
    elif [ -f "$dir" ]; then
        echo "File: $dir"
      
    fi
done

echo "user_array: ${user_array[@]}"
echo "userPath_array: ${userPath_array[@]}"

voldigateJson=$(printf '%s\n' "${user_array[@]}" | "$JQ" -Rn '
  [inputs] | reduce .[] as $item ({}; .[$item] = {})
')

echo "Generated voldigateJson: ${voldigateJson}"

#Iterate through each User to find their projects
for dir in "${userPath_array[0]}"/*; do
    if [ -d "$dir" ]; then
        echo "Directory: $dir"
        
    elif [ -f "$dir" ]; then
        echo "File: $dir"
      
    fi

done
exit 1

#shopt -s globstar #recursive