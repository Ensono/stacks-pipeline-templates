#!/bin/bash

# This script takes a Docker image (and tag) and pulls it from one Azure ACR
# and uploads it to another. This can be used to promote an image between
# subscriptions or

set -exo pipefail

OPTIONS="a:b:c:d:e:f:g:h:i:j:k:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename $0) [OPTION]...

		Required Arguments:
		  -a image:tag		Docker Image and Tag, e.g. \`stacks-java:0.0.2-master\`
		  -b foo.azureacr.io	Pull Docker Registry
		  -c id			Pull ARM Subscription ID
		  -d id			Pull ARM Client ID
		  -e secret		Pull ARM Client Secret
		  -f id			Pull ARM Tenant ID
		  -g bar.azureacr.io	Push Docker Registry
		  -h id			Push ARM Subscription ID
		  -i id			Push ARM Client ID
		  -j secret		Push ARM Client Secret
		  -k id			Push ARM Tenant ID

		Optional Arguments:
		  -Z true|false		Addionally tag the image in the Push Docker Registry with \`latest\`. Default: false
	USAGE_STRING
	)

	echo "$USAGE"

	set -x
}

# Detect `--help`, show usage and exit.
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
		c  ) PULL_ARM_SUBSCRIPTION_ID="$OPTARG";;
		d  ) PULL_ARM_CLIENT_ID="$OPTARG";;
		e  ) PULL_ARM_CLIENT_SECRET="$OPTARG";;
		f  ) PULL_ARM_TENANT_ID="$OPTARG";;
		# Push Docker Creds
		g  ) PUSH_DOCKER_REGISTRY="$OPTARG";;
		h  ) PUSH_ARM_SUBSCRIPTION_ID="$OPTARG";;
		i  ) PUSH_ARM_CLIENT_ID="$OPTARG";;
		j  ) PUSH_ARM_CLIENT_SECRET="$OPTARG";;
		k  ) PUSH_ARM_TENANT_ID="$OPTARG";;

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

if [ -z "$PULL_ARM_SUBSCRIPTION_ID" ]; then
	echo "-c: Missing Pull ARM Subscription ID"
	usage
	exit 4
fi

if [ -z "$PULL_ARM_CLIENT_ID" ]; then
	echo "-d: Missing Pull ARM Client ID"
	usage
	exit 5
fi

if [ -z "$PULL_ARM_CLIENT_SECRET" ]; then
	echo "-e: Missing Pull ARM Client Secret"
	usage
	exit 6
fi

if [ -z "$PULL_ARM_TENANT_ID" ]; then
	echo "-f: Missing Pull ARM Tenant ID"
	usage
	exit 7
fi

# Push Docker Creds
if [ -z "$PUSH_DOCKER_REGISTRY" ]; then
	echo "-g: Missing Push Docker Registry URL"
	usage
	exit 8
fi

if [ -z "$PUSH_ARM_SUBSCRIPTION_ID" ]; then
	echo "-h: Missing Push ARM Subscription ID"
	usage
	exit 9
fi

if [ -z "$PUSH_ARM_CLIENT_ID" ]; then
	echo "-i: Missing Push ARM Client ID"
	usage
	exit 10
fi

if [ -z "$PUSH_ARM_CLIENT_SECRET" ]; then
	echo "-j: Missing Push ARM Client Secret"
	usage
	exit 11
fi

if [ -z "$PUSH_ARM_TENANT_ID" ]; then
	echo "-k: Missing Push ARM Tenant ID"
	usage
	exit 12
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
