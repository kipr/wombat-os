#!/bin/bash

case "$1" in
        start)
                sudo podman stop -a
                sudo podman container prune -f
                sudo podman run -dt --rm --net=host --env IP=192.168.125.1 --name create3_server docker.io/kipradmin/create3_docker
                ;;
        stop)
                sudo podman stop create3_server
                sudo podman stop -a
                ;;
        *)
                echo "Usage: $0 {start|stop}"
                exit 1
                ;;
esac

exit 0
