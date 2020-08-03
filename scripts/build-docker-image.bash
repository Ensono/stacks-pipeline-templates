#!/bin/bash

# This script builds and tags a docker image.

set -exo pipefail

OPTIONS=":a:b:c:d:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a ARGS...		Additional build arguments, such as the path to the Dockerfile.
		  -b image		The image name.
		  -c tag		The tag name.
		  -d name		The container registry name to use in tagging.

		Optional Arguments:
		  -Z .suffix.com	Use the suffix. Default: \`.azurecr.io\`
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
		a  ) DOCKER_BUILD_ADDITIONAL_ARGS="${OPTARG}";;
		b  ) DOCKER_IMAGENAME="${OPTARG}";;
		c  ) DOCKER_IMAGETAG="${OPTARG}";;
		d  ) DOCKER_REGISTRY_NAME="${OPTARG}";;

		# Optional
		Z  ) DOCKER_REGISTRY_SUFFIX="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${DOCKER_BUILD_ADDITIONAL_ARGS}" ]; then
	echo '-a: Missing additional build arguments, such as the path to the Dockerfile'
	exit 1
fi

if [ -z "${DOCKER_IMAGENAME}" ]; then
	echo "-b: Missing Docker image name to use, e.g. 'nginx-ingress'"
	exit 2
fi

if [ -z "${DOCKER_IMAGETAG}" ]; then
	echo '-c: Missing tag name to tag the built image with'
	exit 3
fi

if [ -z "${DOCKER_REGISTRY_NAME}" ]; then
	echo '-d: Missing docker container registry for tagging'
	exit 4
fi

if [ -z "${DOCKER_REGISTRY_SUFFIX}" ]; then
	DOCKER_REGISTRY_SUFFIX=".azurecr.io"
fi

docker build "${DOCKER_BUILD_ADDITIONAL_ARGS}" \
	-t "${DOCKER_IMAGENAME}:${DOCKER_IMAGETAG}" \
	-t "${DOCKER_REGISTRY_NAME}${DOCKER_REGISTRY_SUFFIX}/${DOCKER_IMAGENAME}:${DOCKER_IMAGETAG}"
