This is the installation script that can pull down and start the Prototype Pelion (formerly mbed Cloud) device shadow bridge.

Usage:

   get_bridge.sh [iotf | iothub | awsiot | google | mqtt | mqtt-getstarted | treasuredata | sample]

Arguments:

   iotf - instantiate a bridge for Watson IoT

   iotub - instantiate a bridge for Microsoft IoTHub

   awsiot - instantiate a bridge for AWS IoT

   google - instantiate a bridge for Google CloudIoT

   mqtt - instantiate a bridge for a generic MQTT broker such as Mosquitto
 
   mqtt-getstarted - Like "mqtt" but also has embedded Mosquitto and NodeRED built in by default

   treasuredata - instantiate a bridge for Treasuredata data ingestion

   sample - instantiate a defaulted template sample - the "peer" is a stubbed out example as a starting point

Requirements:

    - macOS or Ubuntu environment with a docker runtime installed and operational by the user account. Windows with DockerToolkit will also work
    
    - a DockerHub account created

    - for "iotf | awsiot | iothub | google | treasuredata" options, 3rd Party cloud accounts must be created. For more information see:

	iotf: https://github.com/ARMmbed/pelion-bridge-container-iotf
	
	iothub: https://github.com/ARMmbed/pelion-bridge-container-iothub
	
	awsiot: https://github.com/ARMmbed/pelion-bridge-container-awsiot

        google: https://github.com/ARMmbed/pelion-bridge-container-google

        treasuredata: https://github.com/ARMmbed/pelion-bridge-container-treasuredata

    - for "mqtt", you will need to setup and ready a MQTT broker.  For more information see:

        mqtt: https://github.com/ARMmbed/pelion-bridge-container-mqtt

    - for "mqtt-getstarted", this is a fully self-contained demo using an integrated MQTT broker and NodeRED. Simply install.

        mqtt-getstarted: https://github.com/ARMmbed/pelion-bridge-container-mqtt-getstarted

    - for "sample", this is a stubbed-out template for initiating development of a bridge to a new 3rd Party (see bridge source link below)

        sample: https://github.com/ARMmbed/pelion-bridge-container-sample


Once the bridge runtime is imported and running, go to the Pelion dashboard and create an API Key. Then:

1). Open a Browser

2). Navigate to: https://<docker host IP address>:8234

3). Accept the self-signed certificate

4). Default username: admin, pw: admin

5). Enter the Pelion API Key, then press SAVE

6). Complete the configuration of the bridge... supply any required credential materials required by the 3rd Party cloud accounts per above. 

7). After entering a given value, press "Save" before editing the next value... 

8). When all values are entered and "Saved", press "Restart"


Additional Notes:

     - Each bridge runtime also has "ssh" (default port: 2222) installed so that you can ssh into the runtime and tinker with it. The default username is "arm" and password "arm1234"

     - ./remove_bridge.sh removes the bridge if desired... it also removes the downloaded docker image
   
     - ./backup_bridge.sh and ./restore_bridge.sh are two scripts that help backup and restore bridge configurations.  You will need to modify DOCKERIP in both to point to your bridge's docker host IP (default is: "localhost")

     - DockerToolkit uses Oracle VirtualBox which pins the default IP address to 192.168.99.100. If you happen to change this in your installation of Docker on MacOS, you will need to edit get_bridge.sh and adjust accordingly.

     - Bridge source is Apache licensed and located here: https://github.com/ARMmbed/pelion-bridge
