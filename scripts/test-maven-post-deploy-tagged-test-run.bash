#!/bin/bash

# Performs a test run with the supplied tags

set -exo pipefail

OPTIONS=":a:b:X:Y:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a Tag	The test tag(s) that are allowed run, e.g. '@Functional or @Smoke or @Performance'
		  -b url	The base URL of the API, e.g. https://dev-java-api.amidostacks.com/api

		Optional Arguments:
		  -X args	Any extra arguments to pass to the test run
		  -Y ignore	Tags to ignore in Cucumber format, e.g. '@Ignore or @Foo'. Empty default
		  -Z location	Optional maven cache directory. Default: \`./.m2\`
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
		# Required
		a  ) GROUP="${OPTARG}";;
		b  ) BASE_URL="${OPTARG}";;

		# Optional
		X  ) EXTRA_ARGS="${OPTARG}";;
		Y  ) IGNORE_GROUPS="${OPTARG}";;
		Z  ) M2_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${GROUP}" ]; then
	echo "-a: Missing a group of tests to run, e.g. '@Functional'" >&2;
	exit 1
fi

if [ -z "${BASE_URL}" ]; then
	echo "-b: Missing the base URL of the application, e.g. https://dev-java-api.amidostacks.com/api" >&2;
	exit 2
fi

if [ -z "${EXTRA_ARGS}" ]; then
	EXTRA_ARGS=""
fi

if [ -n "${IGNORE_GROUPS}" ]; then
	IGNORE_GROUPS="and not(${IGNORE_GROUPS})"
fi

declare -a TAGS_ARRAY
TAGS_ARRAY+=(-Dcucumber.options="--tags '(${GROUP}) ${IGNORE_GROUPS}'")

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

export BASE_URL

./mvnw failsafe:integration-test \
	--no-transfer-progress \
	-Dmaven.repo.local="${M2_LOCATION}" \
	"${TAGS_ARRAY[@]}" \
	"${EXTRA_ARGS[@]}"
