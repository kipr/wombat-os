#!/bin/bash

case "$1" in
        start)
                sudo podman stop create3_server
                sudo podman stop -a
                sudo podman rm create3_server
                CREATE3_SERVER_IP=$(cat /home/kipr/wombat-os/configFiles/create3_server_ip.txt)
                sudo podman run -dt --rm --net=host --env IP=$CREATE3_SERVER_IP --name create3_server docker.io/kipradmin/create3_docker
                ;;
        stop)
                sudo podman stop create3_server
                sudo podman stop -a
                sudo podman rm create3_server
                ;;
        *)
                echo "Usage: $0 {start|stop}"
                exit 1
                ;;
esac

exit 0
