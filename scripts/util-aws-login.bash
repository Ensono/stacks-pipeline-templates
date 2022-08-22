#!/bin/bash

# Logs into `aws` CLI and sets the subscription.

set -exo pipefail

OPTIONS=":a:b:c:d:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a id		AWS Access Key ID
		  -b secret	AWS Secret Access Key
		  -c id		AWS Default Region
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
		a  ) AWS_ACCESS_KEY_ID="${OPTARG}";;
		b  ) AWS_SECRET_ACCESS_KEY="${OPTARG}";;
		c  ) AWS_DEFAULT_REGION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
	echo '-a: Missing AWS Access Key ID'
	exit 1
fi

if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
	echo '-b: Missing AWS Secret Access Key'
	exit 2
fi

if [ -z "${AWS_DEFAULT_REGION}" ]; then
	echo '-c: Missing AWS Default Region'
	exit 3
fi

aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"; aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"; aws configure set default.region "${AWS_DEFAULT_REGION}"