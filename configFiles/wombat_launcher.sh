#!/bin/bash
#Bash script to launch harrogate web IDE and botui GUI
#created 23 May 2023
#edited 9 October 2024

LOGFILE="/var/log/wombat_launcher.log"

# Create the log file if it doesn't exist
sudo touch "$LOGFILE"
sudo chmod 666 "$LOGFILE"

# Clear the log file at the beginning
>"$LOGFILE"

# Redirect all script output to the log file
exec &> >(tee -a "$LOGFILE") # Use tee to see output in terminal and log

echo "[DEBUG] Script started"

echo "[WOMBAT] Launching botui GUI first"
# Run botui in the foreground (this will block the script until botui finishes)
sudo /usr/local/bin/botui &

# Wait for Botui to start and create the AP
AP_NAME=$(sh /usr/bin/wallaby_get_serial.sh)-wombat # Wombat serial/AP name
TIMEOUT=60                                          
CHECK_INTERVAL=5                                    

echo "[DEBUG] Waiting for AP '$AP_NAME' to be created by Botui..."
elapsed_time=0

# Function to check if the AP exists
check_ap_exists() {
    nmcli -f SSID dev wifi | grep -q "$AP_NAME"
}

# Loop until the AP is found or timeout
while [[ $elapsed_time -lt $TIMEOUT ]]; do
    if check_ap_exists; then
        echo "[DEBUG] AP '$AP_NAME' found."
        break
    fi
    sleep $CHECK_INTERVAL
    elapsed_time=$((elapsed_time + CHECK_INTERVAL))
done

if [[ $elapsed_time -ge $TIMEOUT ]]; then
    echo "[ERROR] AP '$AP_NAME' not found within $TIMEOUT seconds."
    exit 1 # Exit if the AP wasn't found
fi

# Run dynamicChannelSwitch.sh in the background
sudo /home/kipr/wombat-os/configFiles/dynamicChannelSwitch.sh &

echo "[WOMBAT] Launching harrogate server.js and other scripts"
export LD_LIBRARY_PATH=/usr/local/qt6/lib:/usr/local/lib
sudo systemctl restart udhcpd.service

# Run harrogate server.js in the background
cd harrogate
sudo node server.js &

# Launch firstTimeScreen.sh in the background
/home/kipr/wombat-os/configFiles/firstTimeScreen.sh &


echo "[DEBUG] Script completed"
