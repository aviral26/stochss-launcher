#!/bin/bash
# trap ctrl_c and call ctrl_c()
trap ctrl_c INT

function ctrl_c(){
	echo
	echo "Stopping StochSS...this may take a while"
	(docker stop stochsscontainer || docker-machine stop stochssdocker || echo "Could not stop container or VM")
	echo "Stopped StochSS"
	exit 0
}

if [[ $(uname -s) == 'Linux' ]]
then
	rm /tmp/first_time /tmp/ad_key
	echo "false" > /tmp/first_time
	echo $(uuidgen) > /tmp/ad_key
	(docker start stochsscontainer || 
		(rm /tmp/first_time &&
		 echo "true" > /tmp/first_time &&
			docker run -d -p 8080:8080 -p 8000:8000 --name=stochsscontainer aviralcse/stochss-initial sh -c "cd stochss-master; rm app/handlers/admin_uuid.txt; echo $(more /tmp/ad_key) > app/handlers/admin_uuid.txt; ./run.ubuntu.sh" &&
			echo "To view Logs, run \"docker logs -f stochsscontainer\" from another terminal"
			) ||
		(echo "neither worked" && exit 1)
		)
	until $(curl --output /dev/null --silent --head --fail $(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080);
	do
		echo "Polling server...."
		sleep 10
	done
	echo "StochSS server is running at the following URL. The browser window should open automatically."
	echo "http://$(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080"
	echo "first time is "
	more /tmp/first_time
	ft=`more /tmp/first_time`
	echo "admin key is "
	more /tmp/ad_key
	if [ "$ft" = true ]
	then
		xdg-open "http://$(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080/login?secret_key=$(more /tmp/ad_key)"
	else
		xdg-open "http://$(docker inspect --format {{.NetworkSettings.IPAddress}} stochsscontainer):8080"
	fi

elif [[ $(uname -s) == 'Darwin' ]]
then
	first_time=false
	docker-machine version || curl -L https://github.com/docker/machine/releases/download/v0.5.3/docker-machine_darwin-amd64 >/usr/local/bin/docker-machine && \
    chmod +x /usr/local/bin/docker-machine && docker-machine version

	# Start up the VM if it's not already running and set environment variables to use docker
	(docker-machine ls stochssdocker | grep -oh "Running") || (docker-machine start stochssdocker || docker-machine create --driver virtualbox stochssdocker)
	docker-machine env stochssdocker
	eval "$(docker-machine env stochssdocker)"

	echo "Docker daemon is now running. The IP address of stochssdocker VM is $(docker-machine ip stochssdocker)"
	#echo $(docker-machine ip stochssdocker) > /tmp/stochss_vm_ip.txt

	# Start container if it already exists, else run aviral/stochss-initial image to create a new one
	(docker start stochsscontainer || 
		(admin_key=$(uuidgen) && 
			first_time=true &&
			docker run -d -p 8080:8080 -p 8000:8000 --name=stochsscontainer aviralcse/stochss-initial sh -c "cd stochss-master; echo $admin_key > app/handlers/admin_uuid.txt; ./run.ubuntu.sh -a $(docker-machine ip stochssdocker)" &&
			echo "Starting StochSS for the first time...this process will take time"
			) ||
		(echo "neither worked" && exit 1)
		)

	# test server is up and connect to it

	until $(curl --output /dev/null --silent --head --fail $(docker-machine ip stochssdocker):8080);
	do
        echo "Polling server...."
        sleep 10
	done
	echo "StochSS server is running at the following URL. The browser window should open automatically."
	echo "http://$(docker-machine ip stochssdocker):8080"
	
	if [ "$first_time" = true ]
	then
		xdg-open "http://$(docker-machine ip stochssdocker):8080/login?secret_key=$admin_key"
	else
		xdg-open "http://$(docker-machine ip stochssdocker):8080"
	fi

else
	echo "Something else"
fi

while :
do 
	read -p "Press CTRL + C to stop server and exit.." key
done