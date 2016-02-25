#!/bin/bash
read -p "Please make you have saved any data you need from this version of StochSS (1.7). Press any key to continue uninstallation or CTRL + C to quit" key
docker-machine version || (echo "Looks like docker-machine is not installed; no VM to delete. Exiting.." && exit 0)
docker-machine start stochssdocker >> .uninstallLog 2>&1
docker-machine env stochssdocker >> .uninstallLog || (echo "cannot set environment" && exit -1)
eval "$(docker-machine env stochssdocker)"
(docker stop stochsscontainer1_7 >> .uninstallLog 2>&1 && docker rm stochsscontainer1_7 && echo "Deleted StochSS 1.7 container") || echo "StochSS container does not exist."
num_containers=`docker ps -aq | wc -l`
if [[ `echo $num_containers` == 0 ]]
then 
	echo "Safe to delete VM. (I have commented out the actual command to delete the VM just to make debugging easier)"
	#docker-machine rm stochssdocker || (echo "Could not remove VM. Exiting.." && exit 0)
else 
 	echo "Not deleting VM as it has other containers."
fi
echo "Done"
read -p "Press any key to exit." key
exit 0

