#!/bin/bash

# Performs a test run which should result in no tests being run

set -exo pipefail

OPTIONS=":a:W:X:Y:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -a Tag	The test tag(s) that are allowed run, e.g. '@Functional or @Smoke or @Performance'

		Optional Arguments:
		  -W location	The location to the serenity HTML reports. Default: "./target/site/serenity"
		  -X location	The location to the failsafe reports. Default: "./target/failsafe-reports"
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

		# Optional
		W  ) TEST_HTML_REPORT_DIRECTORY="${OPTARG}";;
		X  ) TEST_REPORT_DIRECTORY="${OPTARG}";;
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

if [ -z "${TEST_HTML_REPORT_DIRECTORY}" ]; then
	TEST_HTML_REPORT_DIRECTORY="./target/site/serenity"
fi

if [ -z "${TEST_REPORT_DIRECTORY}" ]; then
	TEST_REPORT_DIRECTORY="./target/failsafe-reports"
fi

if [ -n "${IGNORE_GROUPS}" ]; then
	IGNORE_GROUPS="and not(${IGNORE_GROUPS})"
fi

declare -a TAGS_ARRAY
TAGS_ARRAY+=(-Dcucumber.options="--tags 'not (${GROUP}) ${IGNORE_GROUPS}'")

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw failsafe:integration-test \
	--no-transfer-progress \
	-Dmaven.repo.local="${M2_LOCATION}" \
	"${TAGS_ARRAY[@]}"

# If tests ran, then the tags aren't correct.
if [ "$(find "${TEST_HTML_REPORT_DIRECTORY}" -maxdepth 1 | wc -l)" -ne 1 ]; then
	echo "Untagged tests or tests with unknown tags detected!" >&2;
	echo "Please check tags for spelling mistakes or update the allowed tags" >&2;
	echo "Tags: ${TAGS_ARRAY[*]}" >&2;
	exit 1
fi

# There should be basically nothing in here, but it's safer to remove them
# As it won't pollute the test results when they're finally run post-deploy
rm -rf "${TEST_HTML_REPORT_DIRECTORY}" "${TEST_REPORT_DIRECTORY}"
