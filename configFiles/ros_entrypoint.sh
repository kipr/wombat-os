#!/bin/bash
set -e

# setup ros2 environment
source "/opt/ros/$ROS_DISTRO/setup.bash" --
fastdds discovery -i 0 -l 172.17.0.1 -p 11811 & 
exec "$@"