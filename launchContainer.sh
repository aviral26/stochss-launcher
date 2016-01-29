#!/bin/bash

echo "Initializing docker-machine..."
# Check if docker-machine is installed. If not, then download and install it.
docker-machine version || curl -L https://github.com/docker/machine/releases/download/v0.5.3/docker-machine_darwin-amd64 >/usr/local/bin/docker-machine && \
    chmod +x /usr/local/bin/docker-machine && docker-machine version

# Start up the VM if it's not already running and set environment variables to use docker
(docker-machine ls stochssdocker | grep -oh "Running") || (docker-machine start stochssdocker || docker-machine create --driver virtualbox stochssdocker)
docker-machine env stochssdocker
eval "$(docker-machine env stochssdocker)"

echo "Docker daemon is now running. The IP address of stochssdocker VM is $(docker-machine ip stochssdocker)"
#echo $(docker-machine ip stochssdocker) > /tmp/stochss_vm_ip.txt

# Start container if it already exists, else run aviral/stochss-initial image to create a new one
(docker start stochsscontainer || docker run -i -t -p 8080:8080 -p 8000:8000 --name=stochsscontainer aviralcse/stochss-initial sh -c "cd stochss-master; ./run.ubuntu.sh -a $(docker-machine ip stochssdocker)")

