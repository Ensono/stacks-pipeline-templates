#!/bin/bash

# Performs a test run which should result in no tests being run

set -exo pipefail

OPTIONS=":a:Y:Z:"

# TODO: Pull out into params in future
TEST_HTML_REPORT_DIRECTORY="./target/site/serenity"
TEST_REPORT_DIRECTORY="./target/failsafe-reports"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a Tag	The test tag(s) that are allowed run, e.g. '@Functional or @Smoke or @Performance'

		Optional Arguments:
		  -Y ignore		Tags to ignore in Cucumber format, e.g. '@Ignore or @Foo'. Empty default
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

if [ ! -z "${IGNORE_GROUPS}" ]; then
	IGNORE_GROUPS="and not(${IGNORE_GROUPS})"
fi

declare -a TAGS_ARRAY
TAGS_ARRAY+=(-Dcucumber.options="--tags 'not (${GROUP}) ${IGNORE_GROUPS}'")

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

export BASE_URL

./mvnw failsafe:integration-test \
	--no-transfer-progress \
	-Dmaven.repo.local="${M2_LOCATION}" \
	"${TAGS_ARRAY[@]}"

# If tests ran, then the tags aren't correct.
if [ "$(ls -1 -- "${TEST_HTML_REPORT_DIRECTORY}" | wc -l)" -ne 0 ]; then
	echo "Untagged tests or tests with unknown tags detected!" >&2;
	exit 1
fi

rm -rf "${TEST_HTML_REPORT_DIRECTORY}" "${TEST_REPORT_DIRECTORY}"
