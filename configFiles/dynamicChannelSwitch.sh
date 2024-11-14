#!/bin/bash

#Get Wombat Raspberry Pi type (3B or 3B+)
WOMBAT_TYPE=$(awk '/Revision/ {print $3}' /proc/cpuinfo)

#Get the active connection/serial number name (####-wombat)
CONNECTION_NAME=$(nmcli -t -f NAME connection show --active | awk '/-wombat/') # get AP connection name (####-wombat)

#Get current WiFi band and channel
CONNECTION_DETAILS=$(nmcli -f 802-11-wireless.band,802-11-wireless.channel connection show $CONNECTION_NAME)

#Parse the current WiFi band and channel
CURRENT_WIFI_BAND=$(echo "$CONNECTION_DETAILS" | awk 'NR==1 {print $2}')
CURRENT_WIFI_CHANNEL=$(echo "$CONNECTION_DETAILS" | awk 'NR==2 {print $2}')

echo "Current Wifi band: $CURRENT_WIFI_BAND"
echo "Current Wifi channel: $CURRENT_WIFI_CHANNEL"

# Maximum number of APs allowed on a single channel before switching
MAX_APS=45

# Get channels based on current WiFi band
getChannels() {

	if [[ "$WOMBAT_TYPE" == "a020d3" || "$WOMBAT_TYPE" == "a020d4" ]]; then # 3B+ Raspberry Pi (2.4 or 5 GHz)
		
		if [ "$CURRENT_WIFI_BAND" = "a" ]; then # If the current WiFi band is "a" (5GHz)
			CHANNELS=(36 40 44 48 149 153 157 161) # Array of 5GHz channels to switch between
		else                                    # current Wifi band is "bg" (2.4GHz)
			CHANNELS=(1 6 11)                      # Array of 2.4GHz channels to switch between
		fi
	else # 3B Raspberry Pi (2.4GHz only)
	
		CHANNELS=(1 6 11) # Array of 2.4GHz channels to switch between
	fi

	echo "Current channels: ${CHANNELS[@]}"
}

# Function to count the number of APs on the current channel
countAps() {
	local channelNumber=$1
	local apCount=0
	# Scan for nearby APs and count those on the specified channel
	case $channelNumber in
	1) freq=2412 ;;
	6) freq=2437 ;;
	11) freq=2462 ;;
	36) freq=5180 ;;
	40) freq=5200 ;;
	44) freq=5220 ;;
	48) freq=5240 ;;
	149) freq=5745 ;;
	153) freq=5765 ;;
	157) freq=5785 ;;
	161) freq=5805 ;;
	*)
		echo "Unknown Channel"
		exit 1
		;;
	esac

	# Capture the scan results
	scan_results=$(sudo iw dev wlan0 scan | awk -v freq="$freq" '/freq:/{if ($2 == freq) flag=1; else flag=0} flag && /SSID:/ {print $0}')
	if [ -z "$scan_results" ]; then
		echo "No APs found on frequency $freq"
	fi
	# Convert the results into an array
	IFS=$'\n' read -r -d '' -a ssid_array <<<"$scan_results"

	# Add the number of APs to the count
	for ssid in "${ssid_array[@]}"; do
		((apCount++))
	done
	echo $apCount
}

# Function to average the AP count over multiple scans
averageAps() {
	local channelNumber=$1
	local totalAps=0
	local scanCount=2 # Number of scans for averaging

	for ((i = 0; i < scanCount; i++)); do
		ap_count=$(countAps $channelNumber)
		totalAps=$((totalAps + ap_count))
	done

	echo $((totalAps / scanCount)) # Return average
}

switchBandChannel() {
	local changeBand=$1
	local changeChannel=$2

	echo "Requesting change on current band/channel: $CURRENT_WIFI_BAND/$CURRENT_WIFI_CHANNEL to NEW band/channel: $changeBand/$changeChannel"

	# Try to modify the connection
	if [ "$CURRENT_WIFI_CHANNEL" != "$changeChannel" ]; then
		nmcli connection modify $CONNECTION_NAME 802-11-wireless.band $changeBand 802-11-wireless.channel $changeChannel
		nmcli connection down $CONNECTION_NAME
		nmcli radio wifi off
		sleep 2
		nmcli radio wifi on
		nmcli connection up $CONNECTION_NAME
	fi

	echo "New Band: $changeBand with New Channel: $changeChannel"

	# Verify if the new band/channel is applied
	if [ $? -ne 0 ]; then
		echo "Error: Failed to modify connection."
		return 1
	fi

	return 0
}

# Function to find the best channel based on the averaged number of APs
findBestChannel() {
	local bestChannel=${CHANNELS[0]}
	local minAps=999

	for channel in "${CHANNELS[@]}"; do
		avg_ap_count=$(averageAps $channel)

		echo "Channel $channel has an average of $avg_ap_count APs."

		# If the current channel has fewer APs than the best found so far, select it
		if [ "$avg_ap_count" -lt "$minAps" ]; then
			minAps=$avg_ap_count
			bestChannel=$channel
		fi
	done

	echo "Best channel found: $bestChannel with an average of $minAps APs."
	echo "$bestChannel $minAps"

}


# Get the number of APs on the current channel
getChannels
currentChannel=$(nmcli -f 802-11-wireless.channel connection show $CONNECTION_NAME | awk '{print $2}')
currentApCount=$(averageAps $currentChannel)

case $WOMBAT_TYPE in
"a020d3" | "a020d4")
	echo "Wombat is a 3B+"
	echo "Current AP count: $currentApCount on current channel: $currentChannel"
	if [ "$CURRENT_WIFI_BAND" = "a" ]; then # if currently 5GHz

		# Check all 5 GHz channels first
		echo "Checking all 5 GHz channels..."
		result=$(findBestChannel | tee /dev/tty | tail -n 1)

		echo "Result from findBestChannel: $result"

		checkedBestChannel=$(echo $result | awk '{print $1}')
		original5GHzBestChannel=$(echo $result | awk '{print $1}')
		checkedMinAps=$(echo $result | awk '{print $2}')
		echo "Returned best channel: $checkedBestChannel with minimum APs: $checkedMinAps"

		if [ "$checkedMinAps" -lt "$MAX_APS" ]; then #if best channel on 5GHz has less than max APs -> switch to 5GHz found channel
			echo "Found suitable channel $checkedBestChannel on band 'a' with $checkedMinAps APs."
			if switchBandChannel "a" "$checkedBestChannel"; then
				echo "Switched to 5 GHz band, channel $checkedBestChannel."
				exit 0
			else
				echo "Error: Failed to switch to band 'a' with channel $checkedBestChannel."
			fi

		else # if all channels on band 'a' are above the maximum AP limit -> check 2.4GHz band
			echo "All channels on band 'a' are above the maximum AP limit, need to check 2.4 GHz..."
			CHANNELS=(1 6 11)
			result=$(findBestChannel | tee /dev/tty | tail -n 1)

			echo "Result from findBestChannel (2.4GHz): $result"
			checkedBestChannel=$(echo $result | awk '{print $1}')
			checkedMinAps=$(echo $result | awk '{print $2}')
			echo "Returned best channel (2.4GHz): $checkedBestChannel with minimum APs: $checkedMinAps"

			if [ "$checkedMinAps" -lt "$MAX_APS" ]; then #if best channel on 2.4 after 5 GHz check has less than max APs -> switch to 2.4GHz found channel
				echo "Found suitable channel $checkedBestChannel on band 'bg' with $checkedMinAps APs."
				if switchBandChannel "bg" "$checkedBestChannel"; then
					echo "Switched to 2.4 GHz band, channel $checkedBestChannel."
					exit 0
				else
					echo "Error: Failed to switch to band 'bg' with channel $checkedBestChannel."
				fi
			else # if all channels on 2.4 GHz are above the maximum AP limit after 5 GHz check -> set to original 5 GHz best channel
				echo "All channels on band 'bg' are above the maximum AP limit."
				echo "Setting to original 5 GHz best channel: $original5GHzBestChannel"
				if switchBandChannel "a" "$original5GHzBestChannel"; then
					echo "Switched to 5 GHz band, channel $original5GHzBestChannel."
					exit 0
				else
					echo "Error: Failed to switch to band 'a' with channel $original5GHzBestChannel."
				fi
			fi
		fi # end

	elif [ "$CURRENT_WIFI_BAND" = "bg" ]; then # if currently 2.4GHz
		# Check all 2.4 GHz channels first
		echo "Checking all 2.4 GHz channels..."
		result=$(findBestChannel | tee /dev/tty | tail -n 1)

		echo "Result from findBestChannel: $result"

		checkedBestChannel=$(echo $result | awk '{print $1}')
		original24GHzBestChannel=$(echo $result | awk '{print $1}')
		checkedMinAps=$(echo $result | awk '{print $2}')
		echo "Returned best channel: $checkedBestChannel with minimum APs: $checkedMinAps"

		if [ "$checkedMinAps" -lt "$MAX_APS" ]; then #if best channel on 2.4GHz has less than max APs -> switch to 2.4GHz found channel
			echo "Found suitable channel $checkedBestChannel on band 'a' with $checkedMinAps APs."
			if switchBandChannel "bg" "$checkedBestChannel"; then
				echo "Switched to 2.4 GHz band, channel $checkedBestChannel."
				exit 0
			else
				echo "Error: Failed to switch to band 'bg' with channel $checkedBestChannel."
			fi

		else # if all channels on band 'bg' are above the maximum AP limit -> check 5GHz band
			echo "All channels on band 'bg' are above the maximum AP limit, need to check 5 GHz..."
			CHANNELS=(36 40 44 48 149 153 157 161)
			result=$(findBestChannel | tee /dev/tty | tail -n 1)

			echo "Result from findBestChannel (5GHz): $result"
			checkedBestChannel=$(echo $result | awk '{print $1}')
			checkedMinAps=$(echo $result | awk '{print $2}')
			echo "Returned best channel (5GHz): $checkedBestChannel with minimum APs: $checkedMinAps"

			if [ "$checkedMinAps" -lt "$MAX_APS" ]; then #if best channel on 5 after 2.4 GHz check has less than max APs -> switch to 5GHz found channel
				echo "Found suitable channel $checkedBestChannel on band 'bg' with $checkedMinAps APs."
				if switchBandChannel "a" "$checkedBestChannel"; then
					echo "Switched to 5 GHz band, channel $checkedBestChannel."
					exit 0
				else
					echo "Error: Failed to switch to band 'a' with channel $checkedBestChannel."
				fi
			else # if all channels on 5 GHz are above the maximum AP limit after 2.4 GHz check -> set to original 2.4 GHz best channel
				echo "All channels on band 'a' are above the maximum AP limit."
				echo "Setting to original 2.4 GHz best channel: $original24GHzBestChannel"
				if switchBandChannel "bg" "$original24GHzBestChannel"; then
					echo "Switched to 2.4 GHz band, channel $original24GHzBestChannel."
					exit 0
				else
					echo "Error: Failed to switch to band 'bg' with channel $original24GHzBestChannel."
				fi
			fi
		fi # end

	fi
	;;
"a02082" | "a22082" | "a32082" | "a52082" | "a22083")
	echo "Wombat is a 3B"
	echo "Current ap count on channel $currentChannel: $currentApCount"
	if [ "$currentApCount" -ge "$MAX_APS" ]; then
		echo "Maximum number of APs reached. Searching for a better channel..."
		result=$(findBestChannel | tee /dev/tty | tail -n 1)

		echo "Result from findBestChannel: $result"
	fi

	;;
*)
	echo "Unknown Wombat Type"
	exit 1
	;;
esac
