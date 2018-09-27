#!/bin/bash

DOCKER_NAME=noip
DOCKER_PATH=$(pwd)

docker stop ${DOCKER_NAME}
docker rm ${DOCKER_NAME}
docker rmi ${DOCKER_NAME}

docker build \
  -t ${DOCKER_NAME}-config \
  -f ${DOCKER_PATH}/Dockerfile.armv7.config \
  ${DOCKER_PATH}

docker rm noip-config

docker run -i -t \
  --name noip-config \
  -v ${DOCKER_PATH}/config/:/config \
  noip-config bash -c 'make -C /files/noip-2.1.9-1 install; cp /usr/local/etc/no-ip2.conf /config'

docker build \
  -t ${DOCKER_NAME} \
  -f ${DOCKER_PATH}/Dockerfile.armv7 \
  ${DOCKER_PATH}

docker rm ${DOCKER_NAME}

docker run -td \
  --name=${DOCKER_NAME} \
  --restart=unless-stopped \
  -v /etc/localtime:/etc/localtime \
  ${DOCKER_NAME}
