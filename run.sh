#!/bin/bash

ubuntu_install_common() {
  sudo apt-get update
  sudo apt-get dist-upgrade -y
  sudo apt-get install -y --no-install-recommends \
    apt-transport-https \
    curl \
    gnupg-curl \
    htop \
    lsof \
    tree \
    tzdata \
    lsb-release \
    bzip2 \
    unzip \
    xz-utils
}

docker_install() {
  # Docker
  export CHANNEL=stable
  curl -fsSL https://get.docker.com/ | sh
  ## Add Docker daemon configuration
  cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "icc": false,
  "disable-legacy-registry": true,
  "userland-proxy": false,
  "live-restore": true
}
EOF
  ## Start docker service
  sudo systemctl enable docker
  sudo systemctl start docker
  ## Add current user to docker group
  sudo usermod -aG docker $USER

  ## show information
  docker version
  docker info

  # Docker Compose
  sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  ## show docker-compose version
  docker-compose version
}

provision() {
  echo "Provisioning ..."
  ubuntu_install_common
  docker_install
  # Downlaod the Dockerfile and docker-compose.yml
  curl -fsSL https://sourceforge.net/projects/docker-test/files/Docker/docker-compose.yml/download -o docker-compose.yml
  curl -fsSL https://sourceforge.net/projects/docker-test/files/Docker/Dockerfile/download -o Dockerfile
}

provision_java() {
  # Install JRE (Only needed for running PSI locally)
  apt-get update
  apt-get install -y --no-install-recommends  default-jre
}

build() {
  docker build -t practicum -f Dockerfile .
}

up() {
  local name=${1:-practicum}
  local port=${2:-1235}
  local broker_data=${3:-./data/$name/broker}
  local ea_data=${4:-./data/$name/ea}
  
  echo "Starting services for $name ..."
  echo "Port: $port"
  echo "Broker data folder: $broker_data"
  echo "EA data folder: $ea_data"

  BROKER_PORT=$port \
  BROKER_DATA=$broker_data \
  EA_DATA=$ea_data \
    docker-compose -p $name up -d
}

down() {
  local name=${1:-practicum}
  echo "Starting services for $name ..."
  docker-compose -p $name down
}

logs() {
  local name=${1:-practicum}
  shift
  echo "Logs for $name ..."
  docker-compose -p $name logs $@
}

psi() {
  docker create --name temp_psi practicum
  docker cp temp_psi:/app/PSI.jar .
  docker rm temp_psi
  java -jar PSI.jar
}

command=$1
shift
case "$command" in
  build)          build ;;
  up)             up $@ ;;
  down)           down $@ ;;
  logs)           logs $@ ;;
  psi)            psi ;;
  provision)      provision $@ ;;
  provision_java) provision_java ;;
  *)        echo "Usage: <build|up|down|logs|psi|provision|provision_java>" ;;
esac
