#!/bin/bash

echo "You have currently the following containers: "
echo "----------------------------------------------"
list_of_containers=`docker ps -a --format '{{.Names}}' --filter "name=${USER}"`
for name in $list_of_containers
do
  status=`docker ps -a --format '{{.Status}}' --filter "name=${name}"`
  echo "${name#"${USER}_"}     |    Status: ${status}"
done
echo "----------------------------------------------"
echo ""
echo "This command removes a docker container permanently. However, any data saved in /srv/data will not be removed."
echo "Use this command when you want to remove old/unused docker containers."
echo "Name the container which you want to DELETE"
read container

docker stop ${USER}_${container}
docker rm ${USER}_${container}
