#!/bin/bash

# Updates version numbers.

set -exo pipefail

OPTIONS=":Z:V:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -V location	Optional maven package version file. Default: \`1.0.0-SNAPSHOT\`
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
		# Optional
		V  ) PACKAGE_VERSION="${OPTARG}";;
		Z  ) M2_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

if [ -z "${PACKAGE_VERSION}" ]; then
	PACKAGE_VERSION="1.0.0-SNAPSHOT"
fi

MAVEN_OPTIONS=" -Dmaven.repo.local=${M2_LOCATION} --no-transfer-progress -DnewVersion=${PACKAGE_VERSION}"

./mvnw versions:set ${MAVEN_OPTIONS}
