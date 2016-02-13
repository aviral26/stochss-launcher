#!/bin/bash
# trap ctrl_c and call ctrl_c()
trap ctrl_c INT

function ctrl_c(){
	echo
	echo "Stopping StochSS...this may take a while"
	if [[ $(uname -s) == 'Linux' ]]
	then
		(docker stop stochsscontainer || echo "Could not stop container")
	elif [[ $(uname -s) == 'Darwin' ]]
	then
		(docker-machine stop stochssdocker || echo "Could not stop virtual machine")
	else
		echo "Unrecognized operating system"
	fi
	echo "Done"
	exit 0
}

if [[ $(uname -s) == 'Linux' ]]
then
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	(more $DIR/.admin_key) || (echo `uuidgen` > $DIR/.admin_key && echo "written key")
	token=`more $DIR/.admin_key`
	(docker start stochsscontainer || 
		(docker run -d -p 8080:8080 -p 8000:8000 --name=stochsscontainer aviralcse/stochss-initial sh -c "cd stochss-master; ./run.ubuntu.sh -t $token --yy" &&
			echo "To view Logs, run \"docker logs -f stochsscontainer\" from another terminal"
			) ||
		(echo "neither worked" && exit 1)
		)
	
	echo "Starting server. This process may take up to 5 minutes..."
	until $(curl --output /dev/null --silent --head --fail $(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080);
	do
		sleep 10
	done
	echo "StochSS server is running at the following URL. The browser window should open automatically."
	echo "http://$(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080"
	xdg-open "http://$(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080/login?secret_key=$token"
	
elif [[ $(uname -s) == 'Darwin' ]]
then
	docker-machine version || echo "Docker-machine not detected. Please read the installation instructions at xyz"
	# Start up the VM if it's not already running and set environment variables to use docker
	(docker-machine ls stochssdocker | grep -oh "Running") || (docker-machine start stochssdocker || docker-machine create --driver virtualbox stochssdocker)
	docker-machine env stochssdocker
	eval "$(docker-machine env stochssdocker)"
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	(more $DIR/.admin_key) || (echo `uuidgen` > $DIR/.admin_key && echo "written key")
	echo "Docker daemon is now running. The IP address of stochssdocker VM is $(docker-machine ip stochssdocker)"
	token=`more $DIR/.admin_key`
	# Start container if it already exists, else run aviral/stochss-initial image to create a new one
	(docker start stochsscontainer || 
		(first_time=true &&
			docker run -d -p 8080:8080 -p 8000:8000 --name=stochsscontainer aviralcse/stochss-initial sh -c "cd stochss-master; ./run.ubuntu.sh -a $(docker-machine ip stochssdocker) -t $token --yy" &&
			echo "Starting StochSS for the first time."
			) ||
		(echo "neither worked" && exit 1)
		)

	# test server is up and connect to it
	echo "Starting server. This process may take up to 5 minutes..."
	until $(curl --output /dev/null --silent --head --fail $(docker-machine ip stochssdocker):8080);
	do
        sleep 10
	done
	echo "StochSS server is running at the following URL. The browser window should open automatically."
	echo "http://$(docker-machine ip stochssdocker):8080"
	
	open "http://$(docker-machine ip stochssdocker):8080/login?secret_key=`echo $token`"
	

else
	echo "This operating system is not recognized."
fi

while :
do 
	read -p "Press CTRL + C to stop server and exit.." key
done