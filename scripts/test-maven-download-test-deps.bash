#!/bin/bash

# This script downloads any test dependencies that aren't already downloaded by previous steps.
# It also runs any tests that aren't tagged, or who are tagged with unknown tags. If tests are
# detected it'll fail the build. This is to ensure all tags are tagged with known and expected
# tags, this could catch errors earlier.
# The format to pass valid tags in is `Unit | Component` where `|` stands for 'or'.

set -exo pipefail

OPTIONS=":X:Y:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -X 'tag1 [| tag2]...'	A set of tags to allow. Default: 'Unit | Component | Integration | Functional | Performance | Smoke'
		  -Y location		The location of the test reports. Default: 'target/surefire-reports'
		  -Z location		Optional maven cache directory. Default: './.m2'
		USAGE_STRING
	)

	echo "$USAGE"

	set -x
}

# Detect `--help`, show usage and exit
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
done

while getopts $OPTIONS option
do
	case "$option" in
		# Optional
		X  ) ALLOWED_TAGS="$OPTARG";;
		Y  ) TEST_REPORT_DIR="$OPTARG";;
		Z  ) M2_LOCATION="$OPTARG";;

		\? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
		:  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
		*  ) echo "Unimplemented option: -$option. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "$ALLOWED_TAGS" ]; then
	ALLOWED_TAGS="Unit | Component | Integration"
fi

if [ -z "$TEST_REPORT_DIR" ]; then
	TEST_REPORT_DIR="target/surefire-reports"
fi

if [ -z "$M2_LOCATION" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw test --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION" -Dgroups='!'"(${ALLOWED_TAGS})"

# If the directory exists (older versions), or the directory is not empty (newer versions) it means some tests ran.
# Fail the build as there shouldn't be tests with unknown tags.
if [ -d "$TEST_REPORT_DIR" ] && [ $(ls -1A $TEST_REPORT_DIR | wc -l) -ne "0" ]; then
	echo "FAIL: Tests with no tags or with tags not allowed detected." \
		" Please tag tests correctly or update the \`ALLOWED_TAGS\` parameter."
	exit 1
fi
