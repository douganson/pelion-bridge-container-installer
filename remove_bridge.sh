#!/bin/sh

# set -x

DOCKER="docker"
DOCKER_VER="`docker --version`"
PRODUCT="pelion-bridge"

if [ "${DOCKER_VER}X" != "X" ]; then
    ID=`${DOCKER} ps -a | grep home | grep arm | awk '{print $1}'`

    if [ "${ID}X" != "X" ]; then
        echo "Stopping ${PRODUCT} $ID"
        ${DOCKER} stop ${ID}
    else
        echo "No ${PRODUCT} docker runtime instance found... OK"
    fi
    
    if [ "${ID}X" != "X" ]; then
        echo "Removing $ID"
        ${DOCKER} rm --force ${ID}
    fi
    
    echo "Looking for existing container image..."

    ID=`${DOCKER} images | grep ${PRODUCT} | awk '{print $3}'`
    if [ "${ID}X" != "X" ]; then
        echo "Removing ${PRODUCT} image $ID"
        ${DOCKER} rmi --force ${ID}
    else
        echo "No ${PRODUCT} docker runtime image found... (OK)"
    fi
else
    echo "ERROR: docker does not appear to be installed! Please install docker and retry."
    echo "Usage: $0" 
    exit 3
fi
