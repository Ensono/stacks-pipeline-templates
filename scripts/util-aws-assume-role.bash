#!/bin/bash

# Assumes Role for the AWS CLI

set -exo pipefail

OPTIONS=":a:b:c:d:e:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a ad		The AWS Account ID
		  -b id		The Access Key ID
		  -c secret	The Secret Access Key
		  -d cr	    The Name of the role
		  -e rg     The AWS Default Region
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
		d  ) AWS_ACCESS_KEY_ID="${OPTARG}";;
		e  ) AWS_SECRET_ACCESS_KEY="${OPTARG}";;

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

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
	echo '-d: Missing AWS Access Key ID'
	exit 4
fi

if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
	echo '-e: Missing AWS Secret Access Key'
	exit 5
fi


curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

aws sts assume-role --role-arn arn:aws:iam::"${AWS_ACCOUNT_ID}":role/"${AWS_CLUSTER_ROLE}" --role-session-name test --region "${AWS_DEFAULT_REGION}"