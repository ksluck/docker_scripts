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
echo "Name the container which you want to ATTACH:"
read container

docker attach ${USER}_${container}
