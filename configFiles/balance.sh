#!/bin/sh

exec >/var/log/balancer.log

tag="[BALANCER]"
max_retries="10"

echo "${tag} Started"
ap_name="$(sh /home/kipr/wombat-os/flashFiles/wallaby_get_serial.sh)-wombat"

cleanup() {
	# Ensure wifi transmitter is turned back on
	ct="0"
	while [ "${ct}" -lt "${max_retries}" ] && [ "$(nmcli -t radio wifi)" = 'disabled' ]; do
		echo "${tag} Attempting to enable wifi (${ct})"
		nmcli radio wifi on
		ct="$((ct + 1))"
		sleep 1
	done

	# Re-enable connection
	ct="0"
	while [ "${ct}" -lt "${max_retries}" ] && (! nmcli -t -f GENERAL.STATE connection show "${ap_name}" | grep -q 'activated'); do
		echo "${tag} Attempting to bring connection ${ap_name} up ({$ct})"
		nmcli connection up "${ap_name}"
		ct="$((ct + 1))"
		sleep 1
	done

	# Restore normal signal handling
	trap INT EXIT QUIT TERM ABRT

	echo "${tag} Finished"
}

# Ensure that we bring the connection back up before exiting.
# Aside from KILL and STOP (which cannot be caught), these
# should catch all exit scenarios.
trap 'cleanup' INT EXIT QUIT TERM ABRT

# Ensure wifi transmitter is on: required to perform scan
ct="0"
while [ "${ct}" -lt "${max_retries}" ] && [ "$(nmcli -t radio wifi)" = 'disabled' ]; do
	nmcli radio wifi on
	ct="$((ct + 1))"
	sleep 1
done

pi_type="$(awk '/Revision/{print $3}' /proc/cpuinfo)"
case "${pi_type}" in
"a020d3" | "a020d4")
	allowed="/home/kipr/wombat-os/configFiles/allowed_3bplus.txt"
	;;
"a02082" | "a22082" | "a32082" | "a52082" | "a22083")
	allowed="/home/kipr/wombat-os/configFiles/allowed_3b.txt"
	;;
*)
	echo "Unknown Raspberry pi"
	exit 1
	;;
esac

if [ ! -r "${allowed}" ]; then
	echo "${tag} Aborting: ${pi_type} not found"
	exit 1
fi

# List all channels in the area
# Runs three times for tradeoff between speed and accuracy
scan() {
	while ! sudo iw dev wlan0 scan 2>/dev/null; do sleep 2; done
	ct="0"
	while [ "${ct}" -lt "2" ]; do
		sudo iw dev wlan0 scan 2>/dev/null
		ct="$((ct + 1))"
	done
}
all="$(scan | awk '/primary channel:/{print $NF}')"
echo "ALL:"
echo "${all}" | sort -u

# Check if there are unoccupied allowed channels
empty_channels="$(echo "${all}" | sort -u | comm -23 "${allowed}" -)"
echo "EMPTY:"
echo "${empty_channels}"

if [ -n "${empty_channels}" ]; then
	# There are empty channel(s), so pick one at random
	new_channel="$(echo "${empty_channels}" | shuf | head -n1)"
else
	# There are no empty channels, so pick the least crowded
	least_crowded="$(echo "${all}" | grep -Fxf "${allowed}" - | sort | uniq -c | sort -n | head -n1)"
	new_channel="${least_crowded##* }"
fi

# Check which band the new channel occupies
if [ "${new_channel}" -gt 11 ]; then
	# 5GHz
	new_band="a"
else
	# 2.4GHz
	new_band="bg"
fi

# Disable connection before modifying
ct="0"
while [ "${ct}" -lt "${max_retries}" ] && nmcli -t -f GENERAL.STATE connection show "${ap_name}" | grep -q 'activated'; do
	echo "${tag} Attempting to bring connection ${ap_name} down"
	nmcli connection down "${ap_name}"
	ct="$((ct + 1))"
	sleep 1
done

# Disable wifi transmitter before modifying
ct="0"
while [ "${ct}" -lt "${max_retries}" ] && [ "$(nmcli -t radio wifi)" = 'enabled' ]; do
	echo "${tag} Attempting to disable wifi (${ct})"
	nmcli radio wifi off
	ct="$((ct + 1))"
	sleep 1
done

# Modify connection
echo "${tag} Switching ${ap_name} to band ${new_band} on channel ${new_channel}"
nmcli connection modify "${ap_name}" 802-11-wireless.band "${new_band}" 802-11-wireless.channel "${new_channel}" ||
	echo "${tag} Failed to switch ${ap_name} to band ${new_band} on channel ${new_channel}"
