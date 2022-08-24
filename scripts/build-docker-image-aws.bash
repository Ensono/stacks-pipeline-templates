#!/bin/bash

# This script builds and tags a docker image.

set -exo pipefail

OPTIONS=":a:b:c:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a image		The image name.
		  -b tag		The tag name.
		  -c name		The container registry name to use in tagging.

		USAGE_STRING
	)

	echo "${USAGE}"

	set -x
}

# Detect `--help`, show usage and exit
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
done

while getopts "${OPTIONS}" option
do
	case "${option}" in
		a  ) DOCKER_IMAGENAME="${OPTARG}";;
		b  ) DOCKER_IMAGETAG="${OPTARG}";;
		c  ) DOCKER_REGISTRY_NAME="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${DOCKER_IMAGENAME}" ]; then
	echo "-b: Missing Docker image name to use, e.g. 'nginx-ingress'"
	exit 1
fi

if [ -z "${DOCKER_IMAGETAG}" ]; then
	echo '-c: Missing tag name to tag the built image with'
	exit 2
fi

if [ -z "${DOCKER_REGISTRY_NAME}" ]; then
	echo '-d: Missing docker container registry for tagging'
	exit 3
fi

docker build -t "${DOCKER_REGISTRY_NAME}/${DOCKER_IMAGENAME}:${DOCKER_IMAGE_TAG}" .
