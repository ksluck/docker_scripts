# Summary
This is an adapted version of some helpful bash scripts I use on a server on which
we run deep learning experiments with docker. The main purpose of these scripts is to
enable users to quickly use and deploy docker containers without being an expert in Docker
(or who just don't have the time to go down this rabbit hole).
Furthermore, the scripts act as a simple safeguard by making sure users can only
stop, start and delete docker containers which they created, as well as mounting
only their folders from the host system.

As I write below, the bash scipts are a little bit hacky because I did not spend much time on them
and you could certainly improve them. Also, they will not prevent any malicious acts done deliberately by users.
The main reason for this is that you could always mount the root filesystem in docker as a non-sudo user and have then
root access to them via your docker container.

However, the scipts should make sure that no accidents can happen where a Student/Researcher
accidentally deletes the docker container or files of a colleague - but only if they use the scipts.

As it goes with 'hacky' scripts - I cannot guarantee you that the scripts will work, and it is
your duty to go over them and verify that they work on your system. I added a couple helpful comments
in the create_docker file for adaptations you have to make for your system - mostly for the number of CPUs, CPU cores and
GPUs and folders you have on your system.

Feel free to open isues if you have any questions and if you improve the scripts feel free to send me a push request!
I will over time improve these scripts and extend them, but any help is appreciated.

Make sure to have a look at the `create_docker.sh` script - you can adapt it and set some of the variables to adapt the script to your own system.


## Content
- [Summary](#summary)
  * [Content](#content)
  * [Why/What is Docker?](#why-what-is-docker-)
- [Quick Start](#quick-start)
  * [Clone this repository](#clone-this-repository)
  * [Create your own docker container](#create-your-own-docker-container)
  * [Setup your container](#setup-your-container)
  * [Detach/Attach from/to your container](#detach-attach-from-to-your-container)
  * [Using screen](#using-screen)
  * [Start, stop and list docker containers](#start--stop-and-list-docker-containers)
  * [Deleting a container](#deleting-a-container)
  * [Where to store data](#where-to-store-data)
    + [Why you should not store data in the workspace](#why-you-should-not-store-data-in-the-workspace)
    + [Storing data the safe way](#storing-data-the-safe-way)
    + [Volumes](#volumes)
    + [Common issue](#common-issue)
- [Connect to the informatics forum via OpenVPN](#connect-to-the-informatics-forum-via-openvpn)
- [Creating a new user account on the server](#creating-a-new-user-account-on-the-server)


## Why/What is Docker?
If you have never used docker before, the best descriptions is that it feels like
being in a virtual machine without the loss in performance/increased latency you usually have with VMs.

Docker provides you with your own container in which you can install and run any library
you need without interfering with others or the host system. You can find a more detailled explanation here: https://www.docker.com/resources/what-container

# Quick Start
The following section describes the setup and use of docker containers.

## Clone this repository
This repository contains a number of (hacky) bash scripts for your convenience to create,
use and remove docker containers. The scripts are set up in such a way that you can only with great
effort interfere with the docker containers of others.
Clone this repository.

You are now ready to create your first docker container!

## Create your own docker container
The first step will be now to create a docker container from one of the images suitable for your task.
At the moment, images for pytorch, tensorflow and a generic cuda and a plain ubuntu image are provided.

You probably have to go through this process of container generation only once in a while. After you created your container, you can use it indefinitely, start and stop it and install packages and libraries.

The easiest way of generating a docker container is to use the script `create_docker.sh` provided in this repository. It will guide you through the process by asking for your needs, handle the naming and create the container.

In order to start the process execute
```
kevin@Server:~$ ./create_docker.sh
```

It will ask you the following:

```
Enter the name for the new docker container

```
Enter here a name for your container, for example `pytorch`. This name will be used later
when you want to start, stop, attach to or delete this container so it is rather important.
In order to make your container easily identifiable for you, all container names will automatically be prefixed with your username.

```
======================================================================
From which image do you want to create your container?
 Enter [pytorch|tensorflow|cuda|ubuntu] or [own]
pytorch
```
You select here the image from which you want to generate your container.
You canselect from a pytorch, a tensorflow, a generic cuda enabled ubuntu or
a plain ubuntu image.
The initial selection is `pytorch`. Press Enter once you enter your choice.
You can also select an individual docker container from one of the docker repositories, such as
docker hub or nvcr.io by nvidia. To do so enter `own` and then enter first
the name of the repository and then its tag. For example, if you would like
to get the current nvidia pytorch docker image ( https://ngc.nvidia.com/catalog/containers/nvidia:pytorch ) you would
first enter `own` and then the following:
```
Enter a repository (I will give you an example here from https://ngc.nvidia.com/catalog/containers/nvidia:pytorch
nvcr.io/nvidia/pytorch

Enter a tag:
20.09-py3
```
Generally, if you have an command such as `docker pull nvcr.io/nvidia/pytorch:20.09-py3
` then the format is `repository:tag` for the url after pull.

```
======================================================================
GPU Assignment: Which GPU do you want to assign to the container?
 Enter [none|all|0|1|2|3|0,1|0,1,2|1,2,3|1,2|...]
none
```
Here you have the chance to assign none, all or selected GPUs to your container.
This can be useful, for example, if your pytorch code runs by default on device 0.
The initial value is here `none`, which assigns no GPU to the container, thus using only
CPUs. The value `all` lets you access all GPUs from the container. If you want to select
a subset of GPUs, seperate them by comma, for example `1,2` for selecting GPUs 1 and 2.

```
======================================================================
CPU Assignment: How many CPUs do you need? (20 are recommended, 96 max)
 Enter [10|1|2|...|96]
20
```
This questions asks for the maximum number of CPUs the container should have access to.
If your program parallels on CPU level or uses a high number of threads/processes then use
a number smaller than 96 such that other users can still run their programs.
The initial value here is 20 which should be sufficient for most programs.

```
======================================================================
Do you want to run the docker on specific CPUs?
 Enter one of the following:
 auto : Let the host system do its thing
 gpu01 : Select CPUs with a direct connection to GPU 0 and GPU 1
 gpu23 : Select CPUs with a direct connection to GPU 2 and GPU 3
 [0|1|2|0-10|5-20|0,5,10|0-10,15-20|...] : Select CPU threads yourself
```
Here you have the chance to select specific cpu threads which docker should use.
This is only relevant if you want to use a specific GPU. The server has two
CPU cores, each has a direct link to two of the GPUs. Basically, using the
right CPU core for a GPU is a bit faster for sending and receiving data from the GPU.
If you are unsure, select the default `auto`. If you want to see the topology on
the server (ie the connection matrix) use the command `nvidia-smi topo -m`.

```
======================================================================
Memory Assignment: How much memory (in GB) do you need? (32GB recommended, 250 max)
 Enter [1|2|...|250]
32
```
Assign how much memory your container should have access to. Memory is shared between all containers, but this is a useful feature to prevent your container starving host processes or other containers from
memory. The initial value here is 32 GB, which should be sufficient for most programs.
If you need more, consider that this restricts the number of containers you can run at the same time. To protect the host system, the maxium value is 250 GB.

```
======================================================================
Do you want to connect to your host xserver?
This allows to display GUI elements on your screen
This will work on workstations but probably not on headless servers....
[y|n]: n
```
Here you have the option to activate the option forward graphical output of your programs to your host xserver.
This can be useful if you want to use simulators and display their visuals.
Probably, you want to use this option only on your workstation and not on a (headless) server...


```
======================================================================
The following command will be used to create the docker container
 docker run --gpus all --cpus 20 -m 32GB -i -t --shm-size=2g -v /srv/data/ksluck:/srv/data/ksluck/ssd0 --name ksluck_pytorch nvcr.io/nvidia/pytorch:20.07-py3 /bin/bash
If you continue, the docker container will be created and started and drop you into the root shell of the container
Use CTRL+P+Q to detach from the container, or the command exit to stop it
You can use the start and stop scripts to start or stop the container

Continue? [y|n]: y
```
Given all your answers the script will show you now the command it will execute to create your docker container. This includes the addition of volumes and making the container detachable.
Press Enter to create the docker container or `n`, `CRTL+C` to stop the process.

After you press enter your container will be created, started and you will be dropped directly into a root shell:
```
=============
== PyTorch ==
=============

NVIDIA Release 20.07 (build 14714849.1)
PyTorch Version 1.6.0a0+9907a3e

Container image Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.

Copyright (c) 2014-2020 Facebook Inc.
Copyright (c) 2011-2014 Idiap Research Institute (Ronan Collobert)
Copyright (c) 2012-2014 Deepmind Technologies    (Koray Kavukcuoglu)
Copyright (c) 2011-2012 NEC Laboratories America (Koray Kavukcuoglu)
Copyright (c) 2011-2013 NYU                      (Clement Farabet)
Copyright (c) 2006-2010 NEC Laboratories America (Ronan Collobert, Leon Bottou, Iain Melvin, Jason Weston)
Copyright (c) 2006      Idiap Research Institute (Samy Bengio)
Copyright (c) 2001-2004 Idiap Research Institute (Ronan Collobert, Samy Bengio, Johnny Mariethoz)
Copyright (c) 2015      Google Inc.
Copyright (c) 2015      Yangqing Jia
Copyright (c) 2013-2016 The Caffe contributors
All rights reserved.

Various files include modifications (c) NVIDIA CORPORATION.  All rights reserved.
NVIDIA modifications are covered by the license terms that apply to the underlying project or file.

NOTE: MOFED driver for multi-node communication was not detected.
      Multi-node communication performance may be reduced.

root@1108598a8470:/workspace#
```

Congratulations! You just created your first container! :)

## Setup your container

You can now continue and install all necessary libraries or packages, for example vim and htop:
```
root@1108598a8470:/workspace# apt-get update
Fetched 18.3 MB in 3s (6959 kB/s)                           
Reading package lists... Done
root@1108598a8470:/workspace# apt-get install vim htop
Reading package lists... Done
Building dependency tree       
Reading state information... Done
Unpacking htop (2.1.0-3) ...
Setting up htop (2.1.0-3) ...
Processing triggers for mime-support (3.60ubuntu1) ...
```

Test your access to the GPUs with the command `nvidia-smi` and you should see the number of GPUs you requested:
```
root@1108598a8470:/workspace# nvidia-smi
```

Test your pytorch cuda setup with
```
root@1108598a8470:/workspace# python -c 'import torch; print(torch.rand(2,3).cuda())'
tensor([[0.2996, 0.0888, 0.4403],
        [0.8323, 0.7004, 0.0710]], device='cuda:0')
```

## Detach/Attach from/to your container
Okay, you have a container and your deep learning experiment running - what now?

If you want to log off from the server, you can detach the docker container by
pressing the keys
```
CTRL + P + Q
```

This brings yo back to the host system and your container continues to run.

If you want to attach back to the container you can use the script `attach_docker.sh`.
```
kevin@Server:~$ ./attach_docker.sh
You have currently the following containers:
pytorch     |    Status: Up 13 minutes

Name the container which you want to ATTACH
pytorch
root@1108598a8470:/workspace#
```
It will automatically find all your containers base on your user name and ask you which one
you want to attach to. Enter then the name shown, in this example `pytorch`.
Then it will automatically attach you to the docker container and drop you back to where you left off.

## Using screen
It is highly recommended to use screen both in the host system and your docker container.
Screen allows you easily to have multiple shells/sessions open, attach and detach from them and switch easiy.

Screen is already installed on the host system. To install it in your container you have to run
```
apt-get install screen
```
Once you have screen installed, you can create sessions with
```
screen -S NAME bash
```
The addition of `bash` is only necessary in containers. `NAME` is here a name you can choose freely to identify the session.
Once a session is open, you can detach from it by pressing the keys
```
CTRL + A + D
```
This brings you back to your original shell. If you wish to attach back to your scree session execute
```
screen -r NAME
```
To list all screen sessions execute
```
root@1108598a8470:/workspace# screen -ls
There is a screen on:
	1647.test	(08/21/20 12:45:21)	(Detached)
1 Socket in /run/screen/S-root.
```

## Start, stop and list docker containers
The script `list_docker.sh` lists all your containers available.
If a container is stopped, for example because you entered  the command `exit` or
you used the `stop_docker.sh` script, you can restart a container with the script
`start_docker.sh`.

```
kevin@Server:~$ ./stop_docker.sh
You have currently the following containers:
pytorch     |    Status: Up 29 minutes

Name the container which you want to STOP
pytorch

kevin@Server:~$ ./start_docker.sh
You have currently the following containers:
pytorch     |    Status: Exited (0) 6 seconds ago

Name the container which you want to START
pytorch

kevin@Server:~$ ./list_docker.sh
You are executing this commands as user kevin and the following containers are associated with you:
pytorch     |    Status: Up 5 seconds
```

## Deleting a container
You might want to delete a container for multiple reasons: You no longer need it, it is outdated, you screwed up an installation process or just want to start from scratch. Or we are out of disk space :)

To delete a container of your own, just execute the script `delete_docker.sh`. The script will only list your own containers. If you do not use the script but docker commands, triple check you are not accidentally deleting the docker container of a colleague!

```
kevin@Server:~$ ./delete_docker.sh
You have currently the following containers:
pytorch     |    Status: Up 4 minutes

This command removes a docker container permanently. However, any data saved in /srv/data will not be removed.
Use this command when you want to remove old/unused docker containers.
Name the container which you want to DELETE
pytorch

kevin@Server:~$ ./list_docker.sh
You are executing this commands as user kevin and the following containers are associated with you:
kevin@Server:~$
```

As the script says, removing the container will delete all data inside of the container. However, mounted volumes from outside of the container are not touched. This means, all data you do not want to lose permanently should always be stored in `/srv/data` in your container. Use the workspace in your container only for data (for example git repositories) you are okay to lose or libraries/packages.

See also the next section

## Where to store data
When using the `create_docker.sh` script it will automatically mount volumes for you for storing data and results in it, restricting the access to folders of other users.
If you do not use the the script but pure docker commands, you are on your own
(you can use the command shown by the script as template) and have to make sure you do not interfere with the data/folders of other users.

### Why you should not store data in the workspace
If you start up a container you are automatically dropped into the workspace folder. To make it clear: ***If the container is deleted or becomes inaccessible, all data in this folder is LOST.***

### Storing data the safe way
The `create_docker.sh` script automatically mounts folders from the host system in your container. You can find this folders in `/srv/data`. The script will automatically create a folder with your username.

The data in these folders is accessible both from the host system and the docker container, even if the container is deleted. Thus, use these folders for saving code setups or data.

### Common issue
If you create files in your docker container and do this as a root user, then the
files might be inaccessible to you on the host system.
Just execute the following commands in your docker container to make the accessible on the host system:
```
chgrp -R 999 /srv/data
chmod -R g+rw /srv/data
```
These commands define the `docker` group on the host system as owner of these files and
change the group privileges to read and write.

# Creating a new user account on the server
If you add a new user simply add them to the group docker with
```
sudo usermod -a -G docker NAME
```
such that they can execute docker commands.
