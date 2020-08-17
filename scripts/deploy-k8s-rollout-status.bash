#!/bin/bash

# This script takes in a deploy name and tries to wait until it's successfully deployed.

set -exo pipefail

OPTIONS=":a:b:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
			-a deploy		The deployname
			-b namespace	The namespace of the deploy

		Optional Arguments:
			-Z timeout		The k8s formatted timeout to wait for the deployment to rollout. Default '30s'
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
		a  ) DEPLOYMENT_NAME="${OPTARG}";;
		b  ) NAMESPACE="${OPTARG}";;

		# Optional
		Z  ) TIMEOUT="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${DEPLOYMENT_NAME}" ]; then
	echo "-a: Missing Kubernetes Deployment name, such as 'deploy/foobar-app'" >&2
	exit 1
fi

if [ -z "${NAMESPACE}" ]; then
	echo "-b: Missing Kubernetes Deployment namespace, such as 'dev-foobar-app'" >&2
	exit 2
fi

if [ -z "${TIMEOUT}" ]; then
	TIMEOUT="30s"
fi

kubectl rollout status \
	-n "${NAMESPACE}" \
	--timeout ${TIMEOUT} \
	"${DEPLOYMENT_NAME}"
