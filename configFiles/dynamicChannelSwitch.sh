#!/bin/bash

#######################################################################################################
#																								   																		                #
#		Author: Erin Harrington, Tim Corbly																																#
#		Date: 2024-11-19																																							    #
#		Description: Dynamic Wifi band and channel switching script for Wombat, executes on bootup        #
#																																																			#
#######################################################################################################

# Get Wombat Raspberry Pi type (3B or 3B+)
WOMBAT_TYPE=$(awk '/Revision/ {print $3}' /proc/cpuinfo)

# Get AP connection name (####-wombat)
CONNECTION_NAME=$(nmcli -t -f NAME connection show --active | awk '/-wombat/')

# Get current WiFi band and channel
CONNECTION_DETAILS=$(nmcli -f 802-11-wireless.band,802-11-wireless.channel connection show $CONNECTION_NAME)
CURRENT_WIFI_BAND=$(echo "$CONNECTION_DETAILS" | awk 'NR==1 {print $2}')
CURRENT_WIFI_CHANNEL=$(echo "$CONNECTION_DETAILS" | awk 'NR==2 {print $2}')

echo "Current Wifi band: $CURRENT_WIFI_BAND"
echo "Current Wifi channel: $CURRENT_WIFI_CHANNEL"

# Maximum number of APs allowed on a single channel before switching
MAX_APS=45

# Get channels based on current WiFi band
get_channels() {

	if [[ "$WOMBAT_TYPE" == "a020d3" || "$WOMBAT_TYPE" == "a020d4" ]]; then # 3B+ Raspberry Pi (2.4 or 5 GHz)
		# echo "Wombat is a 3B+"
		if [ "$CURRENT_WIFI_BAND" = "a" ]; then # If the current WiFi band is "a" (5GHz)
			CHANNELS=(36 40 44 48 149 153 157 161) # Array of 5GHz channels to switch between
		else                                    # current Wifi band is "bg" (2.4GHz)
			CHANNELS=(1 6 11)                      # Array of 2.4GHz channels to switch between
		fi
	else # 3B Raspberry Pi (2.4GHz only)
		# echo "Wombat is a 3B"
		CHANNELS=(1 6 11) # Array of 2.4GHz channels to switch between
	fi

	echo "Current channels: ${CHANNELS[@]}"
}

# Function to count the number of APs on the current channel
count_aps() {
	local channel_number=$1
	local ap_count=0
	# Scan for nearby APs and count those on the specified channel
	case $channel_number in
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

	# Convert the results into an array
	IFS=$'\n' read -r -d '' -a ssid_array <<<"$scan_results"

	# Print the array elements
	for ssid in "${ssid_array[@]}"; do
		((ap_count++))
	done
	echo $ap_count
}

# Function to average the AP count over multiple scans
average_aps() {
	local channel_number=$1
	local total_aps=0
	local scan_count=2 # Number of scans for averaging

	for ((i = 0; i < scan_count; i++)); do
		ap_count=$(count_aps $channel_number)
		total_aps=$((total_aps + ap_count))
		# sleep 1 # Optional delay between scans
	done

	echo $((total_aps / scan_count)) # Return average
}

# Function to switch the WiFi band and channel
switch_band_channel() {
	local changeBand=$1
	local changeChannel=$2

	echo "Requesting change on current band/channel: $CURRENT_WIFI_BAND/$CURRENT_WIFI_CHANNEL to NEW band/channel: $changeBand/$changeChannel"
	# Try to modify the connection
	nmcli connection modify $CONNECTION_NAME 802-11-wireless.band $changeBand 802-11-wireless.channel $changeChannel
	if [ $? -ne 0 ]; then
		echo "Error: Failed to modify connection."
		return 1
	fi

	if [ "$CURRENT_WIFI_CHANNEL" != "$changeChannel" ]; then
		nmcli connection modify $CONNECTION_NAME 802-11-wireless.band $changeBand 802-11-wireless.channel $changeChannel
		nmcli connection down $CONNECTION_NAME
		nmcli radio wifi off
		sleep 2
		nmcli radio wifi on
		nmcli connection up $CONNECTION_NAME
	fi

	return 0
}

# Function to check the channels on a specific band
check_channels_on_band() {
	local band=$1
	local channels=("${!2}") # Pass the array by reference
	for channel in "${channels[@]}"; do
		avg_ap_count=$(average_aps "$channel")
		echo "Channel $channel on band '$band' has an average of $avg_ap_count APs."

		if [ "$avg_ap_count" -lt "$MAX_APS" ]; then
			echo "Found suitable channel $channel on band '$band' with $avg_ap_count APs."
			if switch_band_channel "$band" "$channel"; then
				echo "Switched to $band band, channel $channel."
				exit 0
			else
				echo "Error: Failed to switch to band '$band' with channel $channel."
			fi
		fi
	done
	echo "All channels on band '$band' are above the maximum AP limit."
}

# Function to find the best channel based on the averaged number of APs
find_best_channel() {
	local best_channel=${CHANNELS[0]}
	local min_aps=999
	#echo "Find Best Channel with CHANNELS: ${CHANNELS[@]}"

	for channel in "${CHANNELS[@]}"; do
		avg_ap_count=$(count_aps_in_parallel $channel)
		echo "Channel $channel has an average of $avg_ap_count APs."

		# If the current channel has fewer APs than the best found so far, select it
		if [ "$avg_ap_count" -lt "$min_aps" ]; then
			min_aps=$avg_ap_count
			best_channel=$channel
		fi
	done

	echo "$best_channel $min_aps"

}

# Function to count APs in parallel for each channel
count_aps_in_parallel() {
	local channel=$1
	average_aps "$channel" &
}

# Main driver code
get_channels
current_channel=$(nmcli -f 802-11-wireless.channel connection show $CONNECTION_NAME | awk '{print $2}')
current_ap_count=$(average_aps $current_channel)

case $WOMBAT_TYPE in
"a020d3" | "a020d4")
	echo "Wombat is a 3B+"
	echo "Current AP count: $current_ap_count on current channel: $current_channel"
	if [ "$CURRENT_WIFI_BAND" = "a" ]; then # if currently 5GHz

		# Check all 5 GHz channels first
		echo "Checking all 5 GHz channels..."
		result=$(find_best_channel | tail -n 1)

		echo "Result from find_best_channel: $result"

		check_best_channel=$(echo $result | awk '{print $1}')
		original_5GHz_best_channel=$(echo $result | awk '{print $1}')
		checked_min_aps=$(echo $result | awk '{print $2}')
		echo "Returned best channel: $check_best_channel with minimum APs: $checked_min_aps"

		if [ "$checked_min_aps" -lt "$MAX_APS" ]; then #if best channel on 5GHz has less than max APs -> switch to 5GHz found channel
			echo "Found suitable channel $check_best_channel on band 'a' with $checked_min_aps APs."
			if switch_band_channel "a" "$check_best_channel"; then
				echo "Switched to 5 GHz band, channel $check_best_channel."
				exit 0
			else
				echo "Error: Failed to switch to band 'a' with channel $check_best_channel."
			fi

		else # if all channels on band 'a' are above the maximum AP limit -> check 2.4GHz band
			echo "All channels on band 'a' are above the maximum AP limit, need to check 2.4 GHz..."
			CHANNELS=(1 6 11)
			result=$(find_best_channel | tail -n 1)

			echo "Result from find_best_channel (2.4GHz): $result"
			check_best_channel=$(echo $result | awk '{print $1}')
			checked_min_aps=$(echo $result | awk '{print $2}')
			echo "Returned best channel (2.4GHz): $check_best_channel with minimum APs: $checked_min_aps"

			if [ "$checked_min_aps" -lt "$MAX_APS" ]; then #if best channel on 2.4 after 5 GHz check has less than max APs -> switch to 2.4GHz found channel
				echo "Found suitable channel $check_best_channel on band 'bg' with $checked_min_aps APs."
				if switch_band_channel "bg" "$check_best_channel"; then
					echo "Switched to 2.4 GHz band, channel $check_best_channel."
					exit 0
				else
					echo "Error: Failed to switch to band 'bg' with channel $check_best_channel."
				fi
			else # if all channels on 2.4 GHz are above the maximum AP limit after 5 GHz check -> set to original 5 GHz best channel
				echo "All channels on band 'bg' are above the maximum AP limit."
				echo "Setting to original 5 GHz best channel: $original_5GHz_best_channel"
				if switch_band_channel "a" "$original_5GHz_best_channel"; then
					echo "Switched to 5 GHz band, channel $original_5GHz_best_channel."
					exit 0
				else
					echo "Error: Failed to switch to band 'a' with channel $original_5GHz_best_channel."
				fi
			fi
		fi # end

	elif [ "$CURRENT_WIFI_BAND" = "bg" ]; then # if currently 2.4GHz
		# Check all 2.4 GHz channels first
		echo "Checking all 2.4 GHz channels..."
		result=$(find_best_channel | tail -n 1)

		echo "Result from find_best_channel: $result"

		check_best_channel=$(echo $result | awk '{print $1}')
		original_24GHZ_best_channel=$(echo $result | awk '{print $1}')
		checked_min_aps=$(echo $result | awk '{print $2}')
		echo "Returned best channel: $check_best_channel with minimum APs: $checked_min_aps"

		if [ "$checked_min_aps" -lt "$MAX_APS" ]; then #if best channel on 2.4GHz has less than max APs -> switch to 2.4GHz found channel
			echo "Found suitable channel $check_best_channel on band 'a' with $checked_min_aps APs."
			if switch_band_channel "bg" "$check_best_channel"; then
				echo "Switched to 2.4 GHz band, channel $check_best_channel."
				exit 0
			else
				echo "Error: Failed to switch to band 'bg' with channel $check_best_channel."
			fi

		else # if all channels on band 'bg' are above the maximum AP limit -> check 5GHz band
			echo "All channels on band 'bg' are above the maximum AP limit, need to check 5 GHz..."
			CHANNELS=(36 40 44 48 149 153 157 161)
			result=$(find_best_channel | tail -n 1)

			echo "Result from find_best_channel (5GHz): $result"
			check_best_channel=$(echo $result | awk '{print $1}')
			checked_min_aps=$(echo $result | awk '{print $2}')
			echo "Returned best channel (5GHz): $check_best_channel with minimum APs: $checked_min_aps"

			if [ "$checked_min_aps" -lt "$MAX_APS" ]; then #if best channel on 5 after 2.4 GHz check has less than max APs -> switch to 5GHz found channel
				echo "Found suitable channel $check_best_channel on band 'bg' with $checked_min_aps APs."
				if switch_band_channel "a" "$check_best_channel"; then
					echo "Switched to 5 GHz band, channel $check_best_channel."
					exit 0
				else
					echo "Error: Failed to switch to band 'a' with channel $check_best_channel."
				fi
			else # if all channels on 5 GHz are above the maximum AP limit after 2.4 GHz check -> set to original 2.4 GHz best channel
				echo "All channels on band 'a' are above the maximum AP limit."
				echo "Setting to original 2.4 GHz best channel: $original_24GHZ_best_channel"
				if switch_band_channel "bg" "$original_24GHZ_best_channel"; then
					echo "Switched to 2.4 GHz band, channel $original_24GHZ_best_channel."
					exit 0
				else
					echo "Error: Failed to switch to band 'bg' with channel $original_24GHZ_best_channel."
				fi
			fi
		fi # end

	fi
	;;
"a02082" | "a22082" | "a32082" | "a52082" | "a22083")
	echo "Wombat is a 3B"
	echo "Current ap count on channel $current_channel: $current_ap_count"

	echo "Checking all 2.4 GHz channels..."
	result=$(find_best_channel)
	echo "Result from find_best_channel: $result"

	check_best_channel=$(echo "$result" | tail -n 1 | awk '{print $1}')
	checked_min_aps=$(echo "$result" | tail -n 1 | awk '{print $2}')
	echo "Returned best channel: $check_best_channel with minimum APs: $checked_min_aps"

	echo "Setting to best channel: $check_best_channel"

	if switch_band_channel "bg" "$check_best_channel"; then
		echo "Switched to channel $check_best_channel on 2.4GHz band."
		exit 0
	else
		echo "Error: Failed to switch to band 'bg' with channel $check_best_channel."
	fi

	;;
*)
	echo "Unknown Wombat Type"
	exit 1
	;;
esac
