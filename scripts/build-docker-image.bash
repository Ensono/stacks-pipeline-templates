#!/bin/bash

set -exo pipefail

# Required
DOCKER_BUILD_ADDITIONAL_ARGS="$1"
DOCKER_IMAGENAME="$2"
DOCKER_IMAGETAG="$3"
DOCKER_CONTAINERREGISTRYNAME="$4"

# Optional
DOCKER_TAGLATEST="$5"

if [ -z "$DOCKER_BUILD_ADDITIONAL_ARGS" ]; then
	echo 'Please additional build arguments such as the path to the Dockerfile.'
	exit 1
fi

if [ -z "$DOCKER_IMAGENAME" ]; then
	echo 'Please supply a Docker Image name to use, e.g. `nginx-ingress`.'
	exit 2
fi

if [ -z "$DOCKER_IMAGETAG" ]; then
	echo 'Please supply a tag name to tag the built image with.'
	exit 3
fi

if [ -z "$DOCKER_CONTAINERREGISTRYNAME" ]; then
	echo 'Please supply the docker container registry for tagging.'
	exit 4
fi

if [ "$DOCKER_TAGLATEST" == "true" ]; then
	DOCKER_LATEST_TAG_ARGUMENT="-t ${DOCKER_CONTAINERREGISTRYNAME}.azurecr.io/${DOCKER_IMAGENAME}:latest"
else
	DOCKER_LATEST_TAG_ARGUMENT=""
fi

docker build ${DOCKER_BUILD_ADDITIONAL_ARGS} \
	-t ${DOCKER_IMAGENAME}:${DOCKER_IMAGETAG} \
	-t ${DOCKER_CONTAINERREGISTRYNAME}.azurecr.io/${DOCKER_IMAGENAME}:${DOCKER_IMAGETAG} \
	${DOCKER_LATEST_TAG_ARGUMENT}
