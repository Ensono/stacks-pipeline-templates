#!/bin/bash

# Creates or updates Kubeconfig

set -exo pipefail

OPTIONS=":a:b:c:d:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a name   EKS Cluster Name
		  -b id		AWS Default Region
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
		a  ) EKS_CLUSTER_NAME="${OPTARG}";;
		b  ) AWS_DEFAULT_REGION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${EKS_CLUSTER_NAME}" ]; then
	echo '-a: Missing EKS Cluster Name'
	exit 1
fi

if [ -z "${AWS_DEFAULT_REGION}" ]; then
	echo '-c: Missing AWS Default Region'
	exit 2
fi

aws eks --region "${AWS_DEFAULT_REGION}" update-kubeconfig --name "${EKS_CLUSTER_NAME}"