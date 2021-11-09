#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

OPTIONS=":Z:U:P:S:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -U location	Optional username for the repository
		  -P location	Optional password for the repository
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
		# Optional
		Z  ) M2_LOCATION="${OPTARG}";;
	  U  ) ARTIFACTORY_USER="${OPTARG}";;
	  P  ) ARTIFACTORY_PASSWORD="${OPTARG}";;
    S  ) SETTINGS_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION+="./.m2"
fi

MAVEN_OPTIONS=" -Dmaven.repo.local=${M2_LOCATION} --no-transfer-progress "

if [ "${ARTIFACTORY_USER}" ]; then
  MAVEN_OPTIONS+=" -Dartifactory.username=${ARTIFACTORY_USER} -Dartifactory.password=${ARTIFACTORY_PASSWORD} "
fi

if [ "${SETTINGS_LOCATION}" ]; then
  MAVEN_OPTIONS+=" --settings ${SETTINGS_LOCATION} "
fi

./mvnw dependency:go-offline ${MAVEN_OPTIONS}
./mvnw install ${MAVEN_OPTIONS}
