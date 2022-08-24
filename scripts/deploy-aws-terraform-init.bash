#!/bin/bash

# This script initialises Terraform with an Azure Blob Storage Backend

set -exo pipefail

OPTIONS=":a:b:c:d:e:f:g:h:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a id		    AWS Access Key ID
		  -b secret	    AWS Secret Access Key
		  -c id         AWS TF State Region
		  -d name		AWS TF State Bucket
		  -e account	AWS TF State Dynamo Table
		  -f container	AWS TF State Encryption
		  -g key	    AWS TF State Key
		  -h workspace  workspace environment
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
		c  ) AWS_TF_STATE_REGION="${OPTARG}";;
		d  ) AWS_TF_STATE_BUCKET"${OPTARG}";;
		e  ) AWS_TF_STATE_DYNAMOTABLE="${OPTARG}";;
		f  ) AWS_TF_STATE_ENCRYPTION="${OPTARG}";;
		g  ) AWS_TF_STATE_KEY="${OPTARG}";;
		h  ) WORKSPACE_NAME="${OPTARG}";;

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

if [ -z "${AWS_TF_STATE_REGION}" ]; then
	echo '-c: Missing AWS TF State Region'
	exit 3
fi

if [ -z "${AWS_TF_STATE_BUCKET}" ]; then
	echo '-d: Missing AWS TF State Bucket'
	exit 4
fi

if [ -z "${AWS_TF_STATE_DYNAMOTABLE}" ]; then
	echo '-e: Missing AWS TF State Dynamotable'
	exit 5
fi

if [ -z "${AWS_TF_STATE_ENCRYPTION}" ]; then
	echo '-f: Missing AWS TF State Key'
	exit 6
fi

if [ -z "${AWS_TF_STATE_KEY}" ]; then
	echo '-g: Missing AWS TF State Key'
	exit 7
fi

if [ -z "${WORKSPACE_NAME}" ]; then
	echo '-h: Missing Terraform Workspace name'
	exit 8
fi

terraform version

terraform init \
	-backend-config="access_key=${AWS_ACCESS_KEY_ID}" \
	-backend-config="secret_key=${AWS_SECRET_ACCESS_KEY}" \
	-backend-config="region=${AWS_DEFAULT_REGION}" \
	-backend-config="bucket=${AWS_TF_STATE_BUCKET}" \
	-backend-config="dynamodb_table=${AWS_TF_STATE_DYNAMOTABLE}" \
	-backend-config="encrypt=${AWS_TF_STATE_ENCRYPTION}" \
	-backend-config="key=${AWS_TF_STATE_KEY}"

terraform workspace select "${WORKSPACE_NAME}" \
	|| terraform workspace new "${WORKSPACE_NAME}"
