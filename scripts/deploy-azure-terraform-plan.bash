#!/bin/bash

# This script runs a Terraform Plan
# Any extra vars should be passed into the script by mapping them
# as environment variables prefixed with `TF_VAR_`, e.g. `TF_VAR_foo=bar`

set -exo pipefail

OPTIONS=":a:b:c:d:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a id		Azure Client ID
		  -b secret	The Azure Client Secret
		  -c id		Azure Tenant ID
		  -d id		Azure Subscription ID

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
		a  ) AZURE_CLIENT_ID="${OPTARG}";;
		b  ) AZURE_CLIENT_SECRET="${OPTARG}";;
		c  ) AZURE_TENANT_ID="${OPTARG}";;
		d  ) AZURE_SUBSCRIPTION_ID="${OPTARG}";;

		# Optional
		Z  ) PLAN_FILE="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${AZURE_CLIENT_ID}" ]; then
	echo '-a: Missing Azure Client ID'
	exit 1
fi

if [ -z "${AZURE_CLIENT_SECRET}" ]; then
	echo '-b: Missing Azure Client Secret'
	exit 2
fi

if [ -z "${AZURE_TENANT_ID}" ]; then
	echo '-c: Missing Azure Tentant ID'
	exit 3
fi

if [ -z "${AZURE_SUBSCRIPTION_ID}" ]; then
	echo '-d: Missing Azure Subscription ID'
	exit 4
fi

if [ -z "${PLAN_FILE}" ]; then
	PLAN_FILE="tfplan"
fi

export ARM_CLIENT_ID="${AZURE_CLIENT_ID}"
export ARM_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
export ARM_TENANT_ID="${AZURE_TENANT_ID}"
export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"

terraform plan -input=false -out="${PLAN_FILE}"
