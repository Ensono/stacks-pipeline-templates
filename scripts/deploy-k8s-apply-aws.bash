#!/bin/bash

# This script takes in a K8s YAML file and will apply it to a cluster

set -exo pipefail

OPTIONS=":a:b:c:d:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
			-a yamlfile	The yaml filename to apply
			-b ad		The AWS Account ID
		 	-c cr	    The Name of the role
		  	-d rg     The AWS Default Region
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
		b  ) AWS_ACCOUNT_ID="${OPTARG}";;
		c  ) AWS_CLUSTER_ROLE="${OPTARG}";;
		d  ) AWS_DEFAULT_REGION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${YAML_FILENAME}" ]; then
	echo "-a: Missing input YAML filename" >&2
	exit 1
fi

if [ -z "${AWS_ACCOUNT_ID}" ]; then
	echo '-b: Missing AWS Account ID'
	exit 2
fi

if [ -z "${AWS_CLUSTER_ROLE}" ]; then
	echo '-c: Missing AWS Cluster Role'
	exit 3
fi

if [ -z "${AWS_DEFAULT_REGION}" ]; then
	echo '-d: Missing AWS Region'
	exit 4
fi

aws sts assume-role --role-arn arn:aws:iam::"${AWS_ACCOUNT_ID}":role/"${AWS_CLUSTER_ROLE}" --role-session-name test --region "${AWS_DEFAULT_REGION}"

aws dynamodb list-tables --endpoint-url https://dynamodb.eu-west-2.amazonaws.com


kubectl apply -f "${YAML_FILENAME}"



kubectl get pods --all-namespaces

