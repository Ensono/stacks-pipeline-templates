#!/bin/bash

# This script takes a Docker image (and tag) and pulls it from one Azure ACR
# and uploads it to another. This can be used to promote an image between
# subscriptions or

set -exo pipefail

OPTIONS=":a:b:c:d:e:f:g:h:i:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a image:tag		Docker Image and Tag, e.g. \`stacks-java:0.0.2-master\`
		  -b foo.azureacr.io	Pull Docker Registry
		  -c id			Pull AWS Access Key ID
		  -d secret		Pull AWS Secret Access Key
		  -e region			Pull AWS Default Region
		  -f bar.azureacr.io	Push Docker Registry
		  -g id			Push AWS Access Key ID
		  -h secret		Push AWS Secret Access Key
		  -i region		Push AWS Default Region

		Optional Arguments:
		  -Z true|false		Addionally tag the image in the Push Docker Registry with \`latest\`. Default: false
		USAGE_STRING
	)

	echo "$USAGE"

	set -x
}

# Detect `--help`, show usage and exit
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
done

while getopts $OPTIONS option
do
	case "$option" in
		# Docker Image
		a  ) DOCKER_IMAGE="$OPTARG";;
		# Pull Docker Creds
		b  ) PULL_DOCKER_REGISTRY="$OPTARG";;
		c  ) PULL_AWS_ACCESS_KEY_ID="$OPTARG";;
		d  ) PULL_AWS_SECRET_ACCESS_KEY="$OPTARG";;
		e  ) PULL_AWS_DEFAULT_REGION="$OPTARG";;
		# Push Docker Creds
		f  ) PUSH_DOCKER_REGISTRY="$OPTARG";;
		g  ) PUSH_AWS_ACCESS_KEY_ID="$OPTARG";;
		h  ) PUSH_AWS_SECRET_ACCESS_KEY="$OPTARG";;
		i  ) PUSH_AWS_DEFAULT_REGION="$OPTARG";;

		# Optional
		Z  ) TAG_LATEST="$OPTARG";;

		\? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
		:  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
		*  ) echo "Unimplemented option: -$option. This is probably unintended." >&2; exit 1;;
	esac
done

# Required #
# Docker Image
if [ -z "$DOCKER_IMAGE" ]; then
	echo "-a: Missing Docker image argument"
	usage
	exit 2
fi

# Pull Docker Creds
if [ -z "$PULL_DOCKER_REGISTRY" ]; then
	echo "-b: Missing Pull Docker Registry URL"
	usage
	exit 3
fi

if [ -z "$PULL_AWS_ACCESS_KEY_ID" ]; then
	echo "-c: Missing Pull AWS Access Key ID"
	usage
	exit 4
fi

if [ -z "$PULL_AWS_SECRET_ACCESS_KEY" ]; then
	echo "-d: Missing Pull AWS Secret Access Key"
	usage
	exit 5
fi

if [ -z "$PULL_AWS_DEFAULT_REGION" ]; then
	echo "-e: Missing Pull AWS Default Region"
	usage
	exit 6
fi

# Push Docker Creds
if [ -z "$PUSH_DOCKER_REGISTRY" ]; then
	echo "-g: Missing Push Docker Registry URL"
	usage
	exit 7
fi

if [ -z "$PUSH_AWS_ACCESS_KEY_ID" ]; then
	echo "-h: Missing Push AWS Access Key ID"
	usage
	exit 8
fi

if [ -z "$PUSH_AWS_SECRET_ACCESS_KEY" ]; then
	echo "-i: Missing Push AWS Secret Access Key"
	usage
	exit 9
fi

if [ -z "$PUSH_AWS_DEFAULT_REGION" ]; then
	echo "-j: Missing Push AWS Default Region"
	usage
	exit 10
fi

echo "Logging in to Pull Azure"
az login --service-principal \
	--username "${PULL_ARM_CLIENT_ID}" \
	--password "${PULL_ARM_CLIENT_SECRET}" \
	--tenant "${PULL_ARM_TENANT_ID}"

az account set -s "${PULL_ARM_SUBSCRIPTION_ID}"
az acr login --name "${PULL_DOCKER_REGISTRY}"

PULL_DOCKER_IMAGE="${PULL_DOCKER_REGISTRY}/${DOCKER_IMAGE}"
docker pull "${PULL_DOCKER_IMAGE}"

echo "Logging in to Push Azure"
az login --service-principal \
	--username "${PUSH_ARM_CLIENT_ID}" \
	--password "${PUSH_ARM_CLIENT_SECRET}" \
	--tenant "${PUSH_ARM_TENANT_ID}"

az account set -s "${PUSH_ARM_SUBSCRIPTION_ID}"
az acr login --name "${PUSH_DOCKER_REGISTRY}"

# Boolean `true` workaround
TAG_LATEST="$(tr '[:upper:]' '[:lower:]' <<< "${TAG_LATEST}")"
if [ "${TAG_LATEST}" == "true" ]; then
	# Strip tag off image
	DOCKER_IMAGE_NO_TAG="${DOCKER_IMAGE%:*}"
	PUSH_DOCKER_IMAGE_LATEST="${PUSH_DOCKER_REGISTRY}/${DOCKER_IMAGE_NO_TAG}:latest"
	docker tag "${PULL_DOCKER_IMAGE}" "${PUSH_DOCKER_IMAGE_LATEST}"

	echo "Pushing \`${DOCKER_IMAGE_LATEST}\`"
	docker push "${PUSH_DOCKER_IMAGE_LATEST}"
fi

PUSH_DOCKER_IMAGE="${PUSH_DOCKER_REGISTRY}/${DOCKER_IMAGE}"
docker tag "${PULL_DOCKER_IMAGE}" "${PUSH_DOCKER_IMAGE}"
echo "Pushing \`${PUSH_DOCKER_IMAGE}\`"
docker push "${PUSH_DOCKER_IMAGE}"
