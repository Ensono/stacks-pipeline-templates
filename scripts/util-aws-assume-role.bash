#!/bin/bash

# Assumes Role for the AWS CLI

set -exo pipefail

OPTIONS=":a:b:c:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a ad		The AWS Account ID
		  -b cr	    The Name of the role
		  -c rg     The AWS Default Region
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
		a  ) AWS_ACCOUNT_ID="${OPTARG}";;
		b  ) AWS_CLUSTER_ROLE="${OPTARG}";;
		c  ) AWS_DEFAULT_REGION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${AWS_ACCOUNT_ID}" ]; then
	echo '-a: Missing AWS Account ID'
	exit 1
fi

if [ -z "${AWS_CLUSTER_ROLE}" ]; then
	echo '-b: Missing AWS Cluster Role'
	exit 2
fi

if [ -z "${AWS_DEFAULT_REGION}" ]; then
	echo '-c: Missing AWS Region'
	exit 3
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update

aws sts assume-role --role-arn arn:aws:iam::"${AWS_ACCOUNT_ID}":role/"${AWS_CLUSTER_ROLE}" --role-session-name test --region "${AWS_DEFAULT_REGION}"