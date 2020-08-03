#!/bin/bash

# This registers preview bindings for Pod Identity
# Note: This is a preview and won't work beyond October 2020
# https://docs.microsoft.com/en-us/azure/aks/use-pod-security-policies

set -exo pipefail

OPTIONS=":"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename $0)
	USAGE_STRING
	)

	echo "${USAGE}"

	set -x
}

# Detect `--help`, show usage and exit.
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
done

while getopts "${OPTIONS}" option
do
	case "${option}" in
		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

az feature register \
	--name MSIPreview \
	--namespace Microsoft.ContainerService

az feature register \
	--name PodSecurityPolicyPreview \
	--namespace Microsoft.ContainerService

az provider register -n Microsoft.ContainerService
