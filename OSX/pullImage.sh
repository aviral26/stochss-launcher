#echo "exporting path $1"
export PATH=$1:$PATH
docker-machine env stochssdocker >> .pullImageLog || (echo "cannot set environment" && exit -1)
eval "$(docker-machine env stochssdocker)"
docker images | grep -oh "aviralcse/stochss-initial" || docker pull aviralcse/stochss-initial
