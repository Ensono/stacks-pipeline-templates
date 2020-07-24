#!/bin/bash

# This script downloads any test dependencies that aren't already downloaded by previous steps.
# It also runs any tests that aren't tagged, or who are tagged with unknown tags. If tests are
# detected it'll fail the build. This is to ensure all tags are tagged with known and expected
# tags, this could catch errors earlier.
# The format to pass valid tags in is `Unit | Component` where `|` stands for 'or'.

set -exo pipefail

# Optional
ALLOWED_TAGS="$1"
M2_LOCATION="$2"
TEST_REPORT_DIR="$3"

if [ -z "$ALLOWED_TAGS" ]; then
	ALLOWED_TAGS="Unit | Component | Integration | Functional | Performance | Smoke"
fi

if [ -z "$M2_LOCATION" ]; then
	M2_LOCATION="./.m2"
fi

if [ -z "$TEST_REPORT_DIR" ]; then
	TEST_REPORT_DIRS="target/surefire-reports"
fi

./mvnw test --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION" -Dgroups='!'"(${ALLOWED_TAGS})"

if [ -d "$TEST_REPORT_DIR" ]; then
	echo "FAIL: Tests with no tags or with tags not allowed detected." \
		" Please tag tests correctly or update the \`ALLOWED_TAGS\` parameter."
	exit 1
fi
