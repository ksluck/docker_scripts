#!/bin/bash

# Change this variable to the number of cpu threads on your computer
max_nmbr_cpus=$(nproc --all)

# Change the data_folder variable to reflect the path to the folder your docker
# container should mount. I do recommend in multiple user settings to use
# the USER variable (this is the user name) such that every user only mounts their
# own folder and it gets harder to delete files of other users 'by accident'.
# You could probably use also '/home/${USER}' or '/home/${USER}/docker' as a
# good alternative to /srv/data
# The script only mounts one folder but you can easily extend it to mount
# other folders as well.

data_folder="/srv/data/${USER}"
docker_folder="/srv/data/${USER}"

echo "Enter the name for the new docker container."
echo "This will be the name you use for starting, stopping, etc and deleting the container later on."
echo "It should be a unique identifier."
read name

# Do NOT change this! Otherwise all other script will not function anymore
# (Alternatively, change it in all other scripts...)
name="${USER}_${name}"

echo "======================================================================"
echo "From which image do you want to create your container?"
echo " Enter [pytorch|tensorflow|cuda|ubuntu] or [own] for entering a repository and tag."
read -e -i "pytorch" image


# This section lists some standard choices for containers
# If you want to use newer images, or other images, then you want to edit this
# section

if [[ "$image" = "pytorch" ]]
then
  repository="nvcr.io/nvidia/pytorch"
  tag="20.08-py3"
elif [[ "$image" = "tensorflow" ]]
then
  repository="nvcr.io/nvidia/tensorflow"
  tag="20.07-tf1-py3"
elif [[ "$image" = "cuda" ]]
then
  repository="nvcr.io/nvidia/cuda"
  tag="11.0-devel"
elif [[ "$image" = "ubuntu" ]]
then
  repository="ubuntu"
  tag="latest"
elif [[ "$image" = "own" ]]
then
  echo "Enter a repository (I will give you an example here from https://ngc.nvidia.com/catalog/containers/nvidia:pytorch "
  read -e -i "nvcr.io/nvidia/pytorch" repository
  echo "Enter a tag"
  read -e -i "20.09-py3" tag
else
  echo "Image name not known"
  exit 1
fi

image="${repository}:${tag}"

echo "======================================================================"
echo "GPU Assignment: Which GPU do you want to assign to the container?"
echo " Enter [none|all|0|1|2|3|0,1|0,1,2|1,2,3|1,2|...]"
read -e -i "none" gpu_assignm

if [[ "$gpu_assignm" == "none" ]]
then
  gpu_command=""
  gpu_assignm=""
else
  if [[ ! "${gpu_assignm}" == "all" ]]
  then
    gpu_assignm="device=${gpu_assignm}"
  fi
  gpu_command="--gpus"
fi

echo "======================================================================"
echo "CPU Assignment: How many CPUs do you need? (20 are recommended, 96 max)"
echo " Enter [10|1|2|...|${max_nmbr_cpus}]"
read -e -i $max_nmbr_cpus cpu_assignm

# Here you might want to change the maximum possible number if your
# server has more than 96 cores

if [ $cpu_assignm -gt $max_nmbr_cpus ]
then
  cpu_assignm=$max_nmbr_cpus
fi

echo "======================================================================"
echo "Do you want to run the docker on specific CPUs?"
echo " Enter one of the following:"
echo " auto : Let the host system do its thing"
echo " gpu01 : Select CPUs with a direct connection to GPU 0 and GPU 1"
echo " gpu23 : Select CPUs with a direct connection to GPU 2 and GPU 3"
echo " [0|1|2|0-10|5-20|0,5,10|0-10,15-20|...] : Select CPU threads yourself"
read -e -i "auto" cpu_cores_selection

# As you might know, if you have more than one CPU core than the transfer
# between certain GPUs and CPUs might be faster
# This section provides a possibility to restrict the docker containers to
# specific GPUs if you know this.
# You might want to adapt the section below

if [ $cpu_cores_selection == "auto" ]
then
	cpu_cores="0-${((max_nmbr_cpus - 1))}"
elif [ $cpu_cores_selection == "gpu01" ]
then
  cpu_cores="0-23,48-71"
elif [ $cpu_cores_selection == "gpu23" ]
then
  cpu_cores="24-47,72-95"
else
  cpu_cores=cpu_cores_selection
fi

echo "======================================================================"
echo "Memory Assignment: How much memory (in GB) do you need? (32GB recommended, 250 max)"
echo " Enter [1|2|...|250]"
read -e -i 32 mem_assignm

# Again, you have to change the following line to reflect the number of GB of
# RAM your machine has.

if [ $mem_assignm -gt 250 ]
then
  mem_assignm=250
fi


echo "======================================================================"
echo "Do you want to connect to your host xserver?"
echo "This allows to display GUI elements on your screen"
echo "This will work on workstations but probably not on headless servers...."
read -p "[y|n]: " -e -i "n" xserv

if [ $xserv == "y" ]
then
  XSOCK=/tmp/.X11-unix
  XAUTH=/tmp/.docker.xauth
  xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
  XDOCKER="-v ${XSOCK}:${XSOCK} -v ${XAUTH}:${XAUTH} -e XAUTHORITY=${XAUTH} -e DISPLAY=$DISPLAY --env='NVIDIA_DRIVER_CAPABILITIES=all'"
else
  XDOCKER=""
fi

echo "======================================================================"
echo "Do you want to forward a port from your docker container to your host system?"
echo "This can be used for jupyter notebooks"
read -p "[y|n]: " -e -i "n" port_forwarding

if [ $port_forwarding == "y" ]
then
  echo "What is the source port? (Docker Container)"
  read -e -i "8888" PORTS
  echo "What is the destination port? (Host System)"
  read -e -i "8888" PORTG
  PORTF="-p ${PORTS}:${PORTG}"
else
  PORTF=""
fi


echo "======================================================================"
echo "The following command will be used to create the docker container"
echo " docker run $gpu_command $gpu_assignm --cpus $cpu_assignm --cpuset-cpus=$cpu_cores -m ${mem_assignm}GB -i -t --shm-size=2g ${PORTF} -v ${data_folder}:${docker_folder} ${XDOCKER} --name $name $image /bin/bash"
echo "If you continue, the docker container will be created and started and drop you into the root shell of the container"
echo "> Use CTRL+P+Q to detach from the container, or the command exit to stop it <"
echo "You can use the start and stop scripts to start or stop the container"
echo "Use the attach_docker.sh script to attach back to a container after detaching."
echo ""

read -p "Continue? [y|n]: " -e -i "y" cont

if [ $cont != "y" ]
then
  exit 1
fi
ndc="NVIDIA_DRIVER_CAPABILITIES=compute,utility,video,display"
docker run $gpu_command $gpu_assignm --cpus $cpu_assignm --cpuset-cpus=$cpu_cores -m ${mem_assignm}GB -i -t --shm-size=2g ${PORTF} -v ${data_folder}:${docker_folder} ${XDOCKER} --env=${ndc} --name $name $image /bin/bash
