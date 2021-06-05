#!/bin/bash
rm -r '/tmp/.docker.xauth'
XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"
xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
echo "Done"
