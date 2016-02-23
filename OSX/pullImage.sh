export PATH=$1:$PATH
sudo docker-machine env stochssdocker || (echo "cannot set environment"&& exit -1))
eval "$(docker-machine env stochssdocker)"
(sudo docker images | grep -oh "aviralcse/stochss-initial") || sudo docker pull aviralcse/stochss-initial
