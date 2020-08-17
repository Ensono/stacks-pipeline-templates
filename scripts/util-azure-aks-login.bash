#!/bin/bash

# Logs into an Azure AKS cluster

set -exo pipefail

OPTIONS=":a:b:c:d:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a rg		The Resource Group of the AKS Cluster
		  -b name	The Name of the AKS Cluster
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
		a  ) AZURE_AKS_RG="${OPTARG}";;
		b  ) AZURE_AKS_NAME="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${AZURE_AKS_RG}" ]; then
	echo '-a: Missing AKS Cluster Resource Group'
	exit 1
fi

if [ -z "${AZURE_AKS_NAME}" ]; then
	echo '-b: Missing AKS Cluster Name'
	exit 2
fi

az aks get-credentials \
	--resource-group "${AZURE_AKS_RG}" \
	--name "${AZURE_AKS_NAME}"
