#!/bin/bash

sudo podman run -dt --rm --net=host --env IP=192.168.125.1 --name create3_server docker.io/kipradmin/create3_docker