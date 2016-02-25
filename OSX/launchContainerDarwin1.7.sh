#!/bin/bash
trap clean_up INT SIGHUP SIGINT SIGTERM

function clean_up(){
	echo
	echo "Please wait while the StochSS 1.7 VM is correctly stopped..."
	docker stop stochsscontainer1_7 || exit 1
	docker-machine stop stochssdocker || exit 1
	echo "Done"
	exit
}

if [[ $(uname -s) == 'Darwin' ]]
then
	docker-machine version || { echo "Docker-machine not detected. Please read the installation instructions at xyz"; exit 1; }
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	# Start up the VM if it's not already running and set environment variables to use docker
	(docker-machine ls stochssdocker | grep -oh "Running") || (docker-machine start stochssdocker >> $DIR/.dockerlog 2>&1 || docker-machine create --driver virtualbox stochssdocker || { echo "Could not create VM. Exiting..."; exit 1; })
	(docker-machine regenerate-certs --force stochssdocker)
	(docker-machine env stochssdocker >> $DIR/.dockerlog)
	eval "$(docker-machine env stochssdocker)" || { echo "Could not connect to VM successfully. Exiting..."; exit 1; }
	DOCKERPATH=$(dirname $(which docker-machine))
	
	(more $DIR/.admin_key >> $DIR/.dockerlog 2>&1) || (echo `uuidgen` > $DIR/.admin_key && echo "Generated key.")
	echo "Docker daemon is now running. The IP address of stochssdocker VM is $(docker-machine ip stochssdocker)"
	token=`more $DIR/.admin_key`
	# Start container if it already exists, else run aviral/stochss-initial image to create a new one
	docker start stochsscontainer1_7 >> $DIR/.dockerlog 2>&1 || { docker images | grep "aviralcse/stochss-initial" | grep -oh "1.7" || { echo "A terminal window should open up to download StochSS. Waiting for image..." && osascript $DIR/StochSS.scpt $DOCKERPATH && { docker images | grep "aviralcse/stochss-initial" | grep -oh "1.7" || { echo "Failed to get image."; clean_up; exit 1; }; }; }; } && first_time=true && docker run -d -p 8080:8080 -p 8000:8000 --name=stochsscontainer1_7 aviralcse/stochss-initial:1.7 sh -c "cd stochss-master; ./run.ubuntu.sh -a $(docker-machine ip stochssdocker) -t $token --yy" >> $DIR/.dockerlog && echo "Starting StochSS for the first time."; } || { echo "Something went wrong."; clean_up; exit 1; }

	# test server is up and connect to it
	echo "Starting server. This process may take up to 5 minutes..."
	until $(curl --output /dev/null --silent --head --fail $(docker-machine ip stochssdocker):8080);
	do
        sleep 10
	done
	echo "StochSS server is running at the following URL. The browser window should open automatically."
	echo "http://$(docker-machine ip stochssdocker):8080/login?secret_key=`echo $token`"
	
	open "http://$(docker-machine ip stochssdocker):8080/login?secret_key=`echo $token`"

else
	echo "This operating system is not recognized."
	clean_up
fi

while :
do 
	sleep 10000
done