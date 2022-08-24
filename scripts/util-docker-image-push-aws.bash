#!/bin/bash

# This script pushes built docker images to the container, optionally tagging
# and pushing latest.

set -exo pipefail

OPTIONS=":a:b:c:d:e:Y:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a image		The image name.
		  -b tag		The tag name.
		  -c name		The container registry name to push to.
		  -d region		The AWS Default Region
		  -e id			The AWS Account ID

		Optional Arguments:
		  -Y true|false		Addionally tag the image with \`latest\` and push. Default: false
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
		a  ) DOCKER_IMAGENAME="${OPTARG}";;
		b  ) DOCKER_IMAGETAG="${OPTARG}";;
		c  ) DOCKER_REGISTRY_NAME="${OPTARG}";;
		d  ) AWS_DEFAULT_REGION="${OPTARG}";;
		e  ) AWS_ACCOUNT_ID="${OPTARG}";;

		# Optional
		Y  ) DOCKER_TAG_LATEST="${OPTARG}";;
		Z  ) DOCKER_REGISTRY_SUFFIX="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${DOCKER_IMAGENAME}" ]; then
	echo "-a: Missing Docker image name to push, e.g. 'nginx-ingress'"
	exit 2
fi

if [ -z "${DOCKER_IMAGETAG}" ]; then
	echo '-b: Missing tag name to push'
	exit 3
fi

if [ -z "${DOCKER_REGISTRY_NAME}" ]; then
	echo '-c: Missing docker container registry for pushing'
	exit 4
fi

if [ -z "${AWS_DEFAULT_REGION}" ]; then
	echo '-c: Missing AWS Default Region'
	exit 5
fi

if [ -z "${AWS_ACCOUNT_ID}" ]; then
	echo '-c: Missing AWS Account ID'
	exit 6
fi

TRIMMED_DOCKER_IMAGETAG="${DOCKER_IMAGETAG:0:128}"
if [ "${DOCKER_IMAGETAG}" != "${TRIMMED_DOCKER_IMAGETAG}" ]; then
	echo "Warning: Docker Image tag trimmed to a maximum of 128 characters!"
	echo "Warning: Using '${TRIMMED_DOCKER_IMAGETAG}'"
	DOCKER_IMAGETAG="${TRIMMED_DOCKER_IMAGETAG}"
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update

aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}".dkr.ecr."${AWS_DEFAULT_REGION}".amazonaws.com

docker build -t stacks-java

docker tag stacks-java:latest "${AWS_ACCOUNT_ID}".dkr.ecr.eu-west-2.amazonaws.com/stacks-java:latest

# DOCKER_IMAGE="${AWS_ACCOUNT_ID}"."${DOCKER_REGISTRY_NAME}"/"${DOCKER_IMAGENAME}":latest

docker push "${AWS_ACCOUNT_ID}".dkr.ecr.eu-west-2.amazonaws.com/stacks-java:latest

# # Boolean `true` workaround
# DOCKER_TAG_LATEST="$(tr '[:upper:]' '[:lower:]' <<< "${DOCKER_TAG_LATEST}")"
# if [ "${DOCKER_TAG_LATEST}" == 'true' ]; then
# 	LATEST_IMAGE="${DOCKER_REGISTRY_NAME}/${DOCKER_IMAGENAME}:latest"
# 	docker tag \
# 		"${DOCKER_IMAGE}" \
# 		"${LATEST_IMAGE}"

# 	docker push "${LATEST_IMAGE}"
# fi
