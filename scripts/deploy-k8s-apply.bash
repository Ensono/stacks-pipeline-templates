#!/bin/bash

# This script takes in a K8s YAML file and will apply it to a cluster

set -exo pipefail

OPTIONS=":a:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
			-a yamlfile	The yaml filename to apply
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
		a  ) YAML_FILENAME="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${YAML_FILENAME}" ]; then
	echo "-a: Missing input YAML filename" >&2
	exit 1
fi

kubectl apply -f "${YAML_FILENAME}"
