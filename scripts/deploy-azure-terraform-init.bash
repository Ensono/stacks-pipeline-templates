#!/bin/bash

# This script initialises Terraform with an Azure Blob Storage Backend

set -exo pipefail

OPTIONS=":a:b:c:d:e:f:g:h:i:"

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
		  -e rg		The resource group name
		  -f account	The storage account name
		  -g container	The container name
		  -h key	The state filename
		  -i workspace	The workspace name to use, usually the env, e.g. 'dev'
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
		e  ) STORAGE_ACCOUNT_RG="${OPTARG}";;
		f  ) STORAGE_ACCOUNT_NAME="${OPTARG}";;
		g  ) CONTAINER_NAME="${OPTARG}";;
		h  ) KEY_NAME="${OPTARG}";;
		i  ) WORKSPACE_NAME="${OPTARG}";;

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

if [ -z "${STORAGE_ACCOUNT_RG}" ]; then
	echo '-e: Missing Azure Storage Account Resource Group'
	exit 5
fi

if [ -z "${STORAGE_ACCOUNT_NAME}" ]; then
	echo '-f: Missing Azure Storage Account Name'
	exit 6
fi

if [ -z "${CONTAINER_NAME}" ]; then
	echo '-g: Missing Azure Storage Container name'
	exit 7
fi

if [ -z "${KEY_NAME}" ]; then
	echo '-h: Missing Azure Storage Filename'
	exit 8
fi

if [ -z "${WORKSPACE_NAME}" ]; then
	echo '-i: Missing Terraform Workspace name'
	exit 9
fi

terraform version

terraform init \
	-backend-config="client_id=${AZURE_CLIENT_ID}" \
	-backend-config="client_secret=${AZURE_CLIENT_SECRET}" \
	-backend-config="tenant_id=${AZURE_TENANT_ID}" \
	-backend-config="subscription_id=${AZURE_SUBSCRIPTION_ID}" \
	-backend-config="resource_group_name=${STORAGE_ACCOUNT_RG}" \
	-backend-config="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
	-backend-config="container_name=${CONTAINER_NAME}" \
	-backend-config="key=${KEY_NAME}"

terraform workspace select "${WORKSPACE_NAME}" \
	|| terraform workspace new "${WORKSPACE_NAME}"
