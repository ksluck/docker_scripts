#!/bin/bash

list_of_containers=`docker ps -a --format '{{.Names}}' --filter "name=${USER}"`

echo "You are executing this commands as user $USER and the following containers are associated with you:"
echo "----------------------------------------------"
for name in $list_of_containers
do
  status=`docker ps -a --format '{{.Status}}' --filter "name=${name}"`
  echo "${name#"${USER}_"}     |    Status: ${status}"
done
echo "----------------------------------------------"
