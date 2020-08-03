#!/bin/bash

# Validates YAML using YAMLint

set -exo pipefail

OPTIONS=":a:b:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a config	Config file location
		  -b files	The files to search
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
		a  ) CONFIG_FILE="${OPTARG}";;
		b  ) BASE_PATH_TO_SEARCH="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${CONFIG_FILE}" ]; then
	echo '-a: Missing path to config file'
	exit 1
fi

if [ -z "${BASE_PATH_TO_SEARCH}" ]; then
	echo '-b: Missing base path to scan'
	exit 2
fi

# Scan the base path and subdirectories and also scan the config file itself.
python3 -m yamllint -sc "${CONFIG_FILE}" "${BASE_PATH_TO_SEARCH}" "${CONFIG_FILE}"
