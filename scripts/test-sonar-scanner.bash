#!/bin/bash

set -exo pipefail

OPTIONS=":a:b:c:d:e:f:g:V:W:X:Y:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename $0) [OPTION]...

		Required Arguments:
		  -a url	The URL to the Sonar(cloud) instance
		  -b name	The Sonar Project Name
		  -c key	The Sonar Project Key
		  -d token	The Sonar Token
		  -e org	The Sonar Organisation Name
		  -f build	The build identifier/number, e.g. '0.0.213-merge' or '1'
		  -g branch	The Source Branch Name, e.g. 'feature/something-awesome'

		Optional Arguments:
		  -V command	The Sonar Command to run. Default: sonar-scanner
		  -W repo	The Remote Repository Name for the PR
		  -X provider	The Pull Request Provider, currently supports: Github.
		  -Y branch	The Target Branch Name. Empty default.
		  -Z pr		The number of the PR. Empty default.

		Options '-W', '-X', '-Y', and '-Z' must all be provided together.
	USAGE_STRING
	)

	echo "${USAGE}"

	set -x
}

# Detect `--help`, show usage and exit.
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
done

while getopts "${OPTIONS}" option
do
	case "${option}" in
		a  ) SONAR_HOST_URL="${OPTARG}";;
		b  ) SONAR_PROJECT_NAME="${OPTARG}";;
		c  ) SONAR_PROJECT_KEY="${OPTARG}";;
		d  ) SONAR_TOKEN="${OPTARG}";;
		e  ) SONAR_ORGANISATION="${OPTARG}";;
		f  ) BUILD_NUMBER="${OPTARG}";;
		g  ) SOURCE_BRANCH_REF="${OPTARG}";;

		# Optional
		V  ) SONAR_COMMAND="${OPTARG}";;
		W  ) PULL_REQUEST_REPO="${OPTARG}";;
		Y  ) TARGET_BRANCH_REF="${OPTARG}";;
		X  ) PULL_REQUEST_PROVIDER="${OPTARG}";;
		Z  ) PULL_REQUEST_NUMBER="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${SONAR_HOST_URL}" ]; then
	echo '-a: Missing Sonar Host URL'
	exit 1
fi

if [ -z "${SONAR_PROJECT_NAME}" ]; then
	echo '-b: Missing Sonar Project Name'
	exit 2
fi

if [ -z "${SONAR_PROJECT_KEY}" ]; then
	echo '-c: Missing Sonar Project Key'
	exit 3
fi

if [ -z "${SONAR_TOKEN}" ]; then
	echo '-d: Missing Sonar Token'
	exit 4
fi

if [ -z "${SONAR_ORGANISATION}" ]; then
	echo '-e: Missing Sonar Organisation Name'
	exit 5
fi

if [ -z "${BUILD_NUMBER}" ]; then
	echo '-f: Missing Build Number'
	exit 6
fi

if [ -z "${SOURCE_BRANCH_REF}" ]; then
	echo '-g: Missing Source Branch Name'
	exit 7
fi

if [ -z "${SONAR_COMMAND}" ]; then
	SONAR_COMMAND="sonar-scanner"
fi

if [ -z "${PULL_REQUEST_REPO}" ]; then
	PULL_REQUEST_REPO=""
fi

if [ -z "${TARGET_BRANCH_REF}" ]; then
	TARGET_BRANCH_REF=""
fi

if [ -z "${PULL_REQUEST_PROVIDER}" ]; then
	PULL_REQUEST_PROVIDER=""
fi

if [ -z "${PULL_REQUEST_NUMBER}" ]; then
	PULL_REQUEST_NUMBER=""
fi

function strip_refs()
{
	local BRANCH_REF="${1}"

	RETURN_BRANCH="$(sed -e "s%^refs/\(heads\|tags\)/%%" <<< ${BRANCH_REF})"
}

strip_refs "${SOURCE_BRANCH_REF}"
SOURCE_BRANCH="${RETURN_BRANCH}"

strip_refs "${TARGET_BRANCH_REF}"
TARGET_BRANCH="${RETURN_BRANCH}"

declare -a EXTRA_SONAR_ARGUMENTS

if [ -z "${PULL_REQUEST_NUMBER}" ]; then
	EXTRA_SONAR_ARGUMENTS+=(-Dsonar.branch.name="${SOURCE_BRANCH}")
	EXTRA_SONAR_ARGUMENTS+=(-Dsonar.branch.target="${TARGET_BRANCH}")
else
	PROVIDER_LOWERCASED="$(tr '[:upper:]' '[:lower:]' <<< "${PULL_REQUEST_PROVIDER}")"

	EXTRA_SONAR_ARGUMENTS+=(-Dsonar.pullrequest.key="${PULL_REQUEST_NUMBER}")
	EXTRA_SONAR_ARGUMENTS+=(-Dsonar.pullrequest.branch="${SOURCE_BRANCH}")
	EXTRA_SONAR_ARGUMENTS+=(-Dsonar.pullrequest.provider="${PROVIDER_LOWERCASED}")
	EXTRA_SONAR_ARGUMENTS+=(-Dsonar.pullrequest.base="${TARGET_BRANCH}")

	if [ "${PROVIDER_LOWERCASED}" == 'github' ]; then
		EXTRA_SONAR_ARGUMENTS+=(-Dsonar.pullrequest.github.repository="${PULL_REQUEST_REPO}")
	fi
fi

"${SONAR_COMMAND}" -v
"${SONAR_COMMAND}" \
	-Dsonar.host.url="${SONAR_HOST_URL}" \
	-Dsonar.projectName="${SONAR_PROJECT_NAME}" \
	-Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
	-Dsonar.login="${SONAR_TOKEN}" \
	-Dsonar.organization="${SONAR_ORGANISATION}" \
	-Dsonar.projectVersion="${BUILD_NUMBER}" \
	"${EXTRA_SONAR_ARGUMENTS[@]}"
