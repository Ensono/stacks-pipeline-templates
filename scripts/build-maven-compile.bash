#!/bin/bash

# Compiles a Maven project, processes test resources, and compiles the tests.
# NOTE: Relies on `build-maven-install.bash` to be run first!

set -exo pipefail

OPTIONS=":Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -Z location	Optional maven cache directory. Default: \`./.m2\`
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

while getopts "${OPTIONS}" option
do
	case "${option}" in
		# Optional
		Z  ) M2_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw compile --no-transfer-progress -Dmaven.repo.local="${M2_LOCATION}" # TODO: Maybe this should run offline?
./mvnw process-test-resources --no-transfer-progress -Dmaven.repo.local="${M2_LOCATION}" --offline
./mvnw test-compile --no-transfer-progress -Dmaven.repo.local="${M2_LOCATION}"
./mvnw process-test-classes --no-transfer-progress -Dmaven.repo.local="${M2_LOCATION}" # TODO: Maybe this should be run offline?
