#!/bin/sh

# set -x

#
# Repo Defaults
#
DOCKER="docker"
OWNER="danson"
PRODUCT="pelion-bridge"
TYPE="$1"
IMAGE="${OWNER}/${PRODUCT}-container-${TYPE}"

#
# Webhook port number for the bridge
#
WEBHOOK_PORT=28520

#
# SSH in bridge - port number 
#
BRIDGE_SSH_PORT="2222"
HOST_SSH_PORT="22"

#
# Bridge configuration page port
#
CONFIG_PAGE_PORT="8234"

#
# Websocket service port within bridge
#
WEBSOCKET_PORT="17362"

#
# MQTT port customization
#
MQTT_PORT="1883"
HOST_MQTT_PORT="2883"
MQTT_OPTIONS=""

#
# MQTT(GetStarted) NodeRED dashboard port
#
NODE_RED_PORT="2880"

#
# Enviornment option: Override webhook port number
#
if [ "${WEBHOOK_PORT_OVERRIDE}X" != "X" ]; then
   WEBHOOK_PORT=${WEBHOOK_PORT_OVERRIDE}
fi

#
# Enable/Disable previous bridge configuration save/restore
#
# Uncomment (or set in shell environment) to ENABLE. Comment out to DISABLE
#
# SAVE_PREV_CONFIG="YES"

#
# Options
#
SCRIPT_OPTIONS="[watson | iothub | awsiot | google | mqtt | mqtt-getstarted | SAMPLE]"

#
# Environment Selection
#
if [ "$(uname)" = "Darwin" ]; then
    if [ ! -h /usr/local/bin/docker-machine ]; then
        # MacOS (toolkit docker installed (OLD))... default is to pin IP address to 192.168.99.100
        IP="192.168.99.100"
	BASE_IP=${IP}
        echo "IP Address:" ${IP}
        IP=${IP}:
    else
        # MacOS (native docker installed) - use localhost..."
	IP="127.0.0.1"
	BASE_IP=${IP}
        echo "IP Address:" ${IP}
        IP=${IP}:
    fi
elif [ "$(uname)" = "MINGW64_NT-10.0" ]; then
    # Windows - Must use the Docker Toolkit with the latest VirtualBox installed... pinned to 192.168.99.100 
    IP="192.168.99.100"
    BASE_IP=${IP}
    echo "IP Address:" ${IP} 
    IP=${IP}:
elif [ "$(uname)" = "MINGW64_NT-6.1" ]; then
    # Windows - Must use the Docker Toolkit with the latest VirtualBox installed... pinned to 192.168.99.100
    IP="192.168.99.100"
    BASE_IP=${IP}
    echo "IP Address:" ${IP}
    IP=${IP}:
else
    # (assume) Linux - docker running as native host - use the host IP address
    IP="`ip route get 8.8.8.8 | awk '{print $NF; exit}'`"
    BASE_IP=${IP}
    echo "IP Address:" ${IP}
    IP=${IP}:
fi

#
# Sanity Check
#
if [ "${TYPE}X" = "X" ]; then
    echo "Required option is missing."
    echo "Usage: $0 ${SCRIPT_OPTIONS}"
    exit 1
fi
if [ "${TYPE}X" != "watsonX" ] && [ "${TYPE}X" != "awsiotX" ] && [ "${TYPE}X" != "iothubX" ] && [ "${TYPE}X" != "googleX" ] && [ "${TYPE}X" != "mqttX" ] && [ "${TYPE}X" != "mqtt-getstartedX" ] && [ "${TYPE}X" != "SAMPLEX" ]
then
    echo "Invalid option supplied."
    echo "Usage: $0 ${SCRIPT_OPTIONS}"
    exit 1
fi

#
# Save a previous Configuration
#
save_config() {
    echo "Saving previous bridge configuration...(default container pw: arm1234)"
    #echo scp -q -P ${BRIDGE_SSH_PORT} arm@${IP}service/conf/service.properties .
    scp -q -P ${BRIDGE_SSH_PORT} arm@${IP}service/conf/service.properties .
    if [ $? != 0 ]; then
        echo "Saving of the previous configuration FAILED"
    else
        echo "Save succeeded."
    fi
    if [ -f service.properties ]; then
        export SAVED_CONFIG="YES"
    else
        export SAVED_CONFIG="NO"
    fi
}

#
# Restore a previous Configuration
#
restore_config() {
   if [ "${SAVED_CONFIG}X" = "YESX" ]; then
 	echo "Waiting for 5 seconds to allow the bridge runtime instance to start up..."
	sleep 5
        SSH_IP=${BASE_IP}
        START="["
        STOP="]:"
        SCP_IP="${SSH_IP}:"
 	echo "Beginning restoration... Updating SSH known_hosts..."
	# echo ssh-keygen -R ${START}${SSH_IP}${STOP}${BRIDGE_SSH_PORT}
	ssh-keygen -R ${START}${SSH_IP}${STOP}${BRIDGE_SSH_PORT}
        echo "Restoring previous configuration... (default container pw: arm1234)"
        # echo scp -q -P ${BRIDGE_SSH_PORT} service.properties arm@${SCP_IP}service/conf
        scp -q -q -P ${BRIDGE_SSH_PORT} service.properties arm@${SCP_IP}service/conf
	if [ $? != 0 ]; then
	    echo "Restoration of the previous configuration FAILED"
	else
	    echo "Restoration succeeded... Restarting the bridge runtime..."
	    #echo ssh -l arm -p ${BRIDGE_SSH_PORT} ${SSH_IP} "sh -c 'cd /home/arm; nohup ./restart.sh > /dev/null 2>&1'"
	    ssh -l arm -p ${BRIDGE_SSH_PORT} ${SSH_IP} "sh -c 'cd /home/arm; nohup ./restart.sh > /dev/null 2>&1'"
	    if [ $? != 0 ]; then
                echo "Pelion Bridge restart FAILED"
		exit 4
            else
                echo "Pelion Bridge restarted."
	    fi
	    echo "Bridge runtime restarted... Restarting the properties editor..."
            #echo ssh -l arm -p  ${BRIDGE_SSH_PORT} ${SSH_IP} "sh -c 'cd /home/arm/properties-editor; nohup ./restartPropertiesEditor.sh > /dev/null 2>&1'"
	    ssh -l arm -p  ${BRIDGE_SSH_PORT} ${SSH_IP} "sh -c 'cd /home/arm/properties-editor; nohup ./restartPropertiesEditor.sh > /dev/null 2>&1'"
            if [ $? != 0 ]; then
                echo "Properties editor restart FAILED"
 	        exit 5
            else
                echo "Properties editor restarted."
            fi
	fi
        rm -f service.properties 2>&1 1>/dev/null
   fi
}

#
# Finalize the MQTT options
#
if [ "${TYPE}X" = "mqttX" ]; then
    MQTT_OPTIONS="-p ${IP}${MQTT_PORT}:${MQTT_PORT}"
fi
if [ "${TYPE}X" = "mqtt-getstartedX" ]; then
    MQTT_OPTIONS="-p ${IP}${MQTT_PORT}:${HOST_MQTT_PORT} -p ${IP}${NODE_RED_PORT}:1880"
fi

# 
# Docker Run port config
#
DOCKER_PORT_CONFIG="-p ${IP}${WEBHOOK_PORT}:${WEBHOOK_PORT} -p ${IP}${BRIDGE_SSH_PORT}:${HOST_SSH_PORT} -p ${IP}${CONFIG_PAGE_PORT}:${CONFIG_PAGE_PORT} -p ${IP}${WEBSOCKET_PORT}:${WEBSOCKET_PORT} ${MQTT_OPTIONS}"

#
# Import and Run
#
DOCKER_VER="`docker --version`"
if [ "${DOCKER_VER}X" = "X" ]; then
    echo "ERROR: docker does not appear to be installed! Please install docker and retry."
    echo "Usage: $0 ${SCRIPT_OPTIONS}"
    exit 2
else
    ID=`${DOCKER} ps -a | grep home | grep arm | awk '{print $1}'`
    if [ "${ID}X" != "X" ]; then
        if [ "${SAVE_PREV_CONFIG}X" = "YESX" ]; then
            save_config $*
        fi
        echo "Stopping $ID"
        docker stop ${ID}
    else
        echo "No running Pelion bridge runtime instance found... OK"
    fi
    
    if [ "${ID}X" != "X" ]; then
        echo "Removing Pelion bridge runtime instance $ID"
        docker rm --force ${ID}
    fi
    
    echo "Looking for existing Pelion bridge runtime image..."

    ID=`${DOCKER} images | grep pelion-bridge | awk '{print $3}'`
    if [ "${ID}X" != "X" ]; then
        echo "Removing Image $ID"
        docker rmi --force ${ID}
    else
        echo "No Pelion bridge runtime image found... OK"
    fi

    #
    # Pull and Invoke from DockerHub
    #
    echo ""
    echo "Pelion bridge Image:" ${IMAGE}
    echo "Pulling Pelion device shadow bridge runtime from DockerHub(tm)..."
    ${DOCKER} pull ${IMAGE}
    if [ "$?" = "0" ]; then
       echo "Starting Pelion shadow bridge runtime..."
       echo ${DOCKER} run -d ${DOCKER_PORT_CONFIG} -t ${IMAGE}  /home/arm/start_instance.sh
       ${DOCKER} run -d ${DOCKER_PORT_CONFIG} -t ${IMAGE}  /home/arm/start_instance.sh
       if [ "$?" = "0" ]; then
           echo "Pelion bridge started!  SSH is available to log into the bridge runtime"
	   if [ "${SAVE_PREV_CONFIG}X" = "YESX" ]; then
 	       if [ "${SAVED_CONFIG}X" = "YESX" ]; then
	           echo ""
		   restore_config $*
               fi
	   fi
	   exit 0
       else
	   echo "Pelion device shadow bridge runtime FAILED to start!"
           exit 5
       fi
    else 
	echo "Pelion device shadow bridge runtime import FAILED!" 
        exit 6
    fi 
fi
