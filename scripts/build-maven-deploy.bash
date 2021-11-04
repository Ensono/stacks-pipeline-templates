#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

OPTIONS=":Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -Z location	Optional maven cache directory. Default: \`./.m2\`
		  -S location	Optional maven settings file. Default: \`./.mvn/settings.xml\`
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
    S  ) SETTINGS_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

if [ -z "${SETTINGS_LOCATION}" ]; then
	SETTINGS_LOCATION="./.mvn/settings.xml"
fi

ARTIFACTORY_ADMIN="admin"
ARTIFACTORY_PASSWORD="password"

./mvnw deploy --no-transfer-progress --settings ${SETTINGS_LOCATION} -Dmaven.repo.local="${M2_LOCATION}"  -Dartifactory.username=${ARTIFACTORY_ADMIN} -Dartifactory.password=${ARTIFACTORY_PASSWORD}
