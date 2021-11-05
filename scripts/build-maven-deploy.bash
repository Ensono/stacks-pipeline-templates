#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

OPTIONS=":u:p:Z:S:F:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -u username for the repository
		  -p password for the repository

		Optional Arguments:
		  -F location Optional pom.xml file location. Default: \`pom.xml\`
		  -S location	Optional maven settings file. Default: \`./.mvn/settings.xml\`
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
	  u ) ARTIFACTORY_USER="${OPTARG}";;
	  p ) ARTIFACTORY_PASSWORD="${OPTARG}";;

		# Optional
		F  ) POM_FILE="${OPTARG}";;
    S  ) SETTINGS_LOCATION="${OPTARG}";;
		Z  ) M2_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${POM_FILE}" ]; then
	POM_FILE="pom.xml"
fi

if [ -z "${SETTINGS_LOCATION}" ]; then
	SETTINGS_LOCATION="./.mvn/settings.xml"
fi

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw deploy -Dmaven.test.skip=true --no-transfer-progress -f  ${POM_FILE} --settings ${SETTINGS_LOCATION} -Dmaven.repo.local="${M2_LOCATION}"  -Dartifactory.username=${ARTIFACTORY_USER} -Dartifactory.password=${ARTIFACTORY_PASSWORD}
