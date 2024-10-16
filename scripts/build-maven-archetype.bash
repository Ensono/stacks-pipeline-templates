#!/bin/bash

# Compiles a Maven project, processes test resources, and compiles the tests.
# NOTE: Relies on `build-maven-install.bash` to be run first!

set -exo pipefail

OPTIONS=":Z:A:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -A location Optional archetype.properties file location. Default: \`archetype.properties\`
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
		A  ) ARCHETYPE_PROPERTIES_FILE="${OPTARG}";;
		Z  ) M2_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${ARCHETYPE_PROPERTIES_FILE}" ]; then
	ARCHETYPE_PROPERTIES_FILE="archetype.properties"
fi

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

MAVEN_OPTIONS=("--settings settings.xml" "-Dmaven.repo.local=${M2_LOCATION}" "--no-transfer-progress" "-DpropertyFile=${ARCHETYPE_PROPERTIES_FILE}")

echo "<settings></settings>" > settings.xml

./mvnw clean archetype:create-from-project ${MAVEN_OPTIONS[@]}
