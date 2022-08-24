#!/bin/bash

# This script runs a Terraform Apply
# Any extra vars should be passed into the script by mapping them
# as environment variables prefixed with `TF_VAR_`, e.g. `TF_VAR_foo=bar`

set -exo pipefail

OPTIONS=":a:b:c:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a id		AWS Access Key ID 
		  -b secret	AWS Secret Access Key
		  -c id		AWS Default Region

		Optional Arguments:
		  -Z plan	Planfile name. Default: 'tfplan'
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

		# Optional
		Z  ) PLAN_FILE="${OPTARG}";;

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

if [ -z "${PLAN_FILE}" ]; then
	PLAN_FILE="tfplan"
fi

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

terraform apply "${PLAN_FILE}"
