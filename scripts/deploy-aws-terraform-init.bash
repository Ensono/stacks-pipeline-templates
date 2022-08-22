#!/bin/bash

# This script initialises Terraform with an Azure Blob Storage Backend

set -exo pipefail

OPTIONS=":a:b:c:d:e:f:g:h:i:j:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a id		    AWS Access Key ID
		  -b secret	    AWS Secret Access Key
		  -c id		    AWS Default Region
		  -d id         AWS TF State Region
		  -e name		AWS TF State Bucket
		  -f account	AWS TF State Dynamo Table
		  -g container	AWS TF State Encryption
		  -h key	    AWS TF State Key
		  -i workspace  workspace environment
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
		d  ) AWS_TF_STATE_REGION="${OPTARG}";;
		e  ) AWS_TF_STATE_BUCKET"${OPTARG}";;
		f  ) AWS_TF_STATE_DYNAMOTABLE="${OPTARG}";;
		g  ) AWS_TF_STATE_ENCRYPTION="${OPTARG}";;
		h  ) AWS_TF_STATE_KEY="${OPTARG}";;
		i  ) WORKSPACE_NAME="${OPTARG}";;

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

if [ -z "${AWS_TF_STATE_REGION}" ]; then
	echo '-a: Missing AWS TF State Region'
	exit 1
fi

if [ -z "${AWS_TF_STATE_BUCKET}" ]; then
	echo '-b: Missing AWS TF State Bucket'
	exit 2
fi

if [ -z "${AWS_TF_STATE_DYNAMOTABLE}" ]; then
	echo '-c: Missing AWS TF State Dynamotable'
	exit 3
fi

if [ -z "${AWS_TF_STATE_ENCRYPTION}" ]; then
	echo '-h: Missing AWS TF State Key'
	exit 8
fi

if [ -z "${AWS_TF_STATE_KEY}" ]; then
	echo '-h: Missing AWS TF State Key'
	exit 9
fi

if [ -z "${WORKSPACE_NAME}" ]; then
	echo '-i: Missing Terraform Workspace name'
	exit 10
fi

terraform version

terraform init \
	-backend-config="aws_access_key_id=${AWS_ACCESS_KEY_ID}" \
	-backend-config="aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" \
	-backend-config="aws_default_region=${AWS_DEFAULT_REGION}" \
	-backend-config="aws_tf_state_region=${AWS_TF_STATE_REGION}" \
	-backend-config="aws_tf_state_bucket=${AWS_TF_STATE_BUCKET}" \
	-backend-config="aws_tf_state_dynamotable=${AWS_TF_STATE_DYNAMOTABLE}" \
	-backend-config="aws_tf_state_encryption=${AWS_TF_STATE_ENCRYPTION}" \
	-backend-config="aws_tf_state_key=${AWS_TF_STATE_KEY}"

terraform workspace select "${WORKSPACE_NAME}" \
	|| terraform workspace new "${WORKSPACE_NAME}"
