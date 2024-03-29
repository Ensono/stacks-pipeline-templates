#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

OPTIONS=":u:p:Z:S:F:R:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -u username for the repository
		  -p password for the repository

		Optional Arguments:
		  -R location Optional alternative deployment repository. Default: \`\`
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
        R  ) ALT_DEPLOYMENT_REPOSITORY="${OPTARG}";;
        F  ) POM_FILE="${OPTARG}";;
        S  ) SETTINGS_LOCATION="${OPTARG}";;
        Z  ) M2_LOCATION="${OPTARG}";;

        \? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
        :  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
        *  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
    esac
done

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

MAVEN_OPTIONS=" -Dmaven.test.skip=true -Dmaven.repo.local=${M2_LOCATION}  -Dartifactory.username=${ARTIFACTORY_USER} -Dartifactory.password=${ARTIFACTORY_PASSWORD}  --no-transfer-progress "

if [ "${SETTINGS_LOCATION}" ]; then
	MAVEN_OPTIONS+=" --settings ${SETTINGS_LOCATION} "
fi

if [ "${POM_FILE}" ]; then
	MAVEN_OPTIONS+=" -f  ${POM_FILE} "
fi

if [ "${ALT_DEPLOYMENT_REPOSITORY}" ]; then
	MAVEN_OPTIONS+=" -DaltDeploymentRepository=${ALT_DEPLOYMENT_REPOSITORY} "
fi

./mvnw deploy ${MAVEN_OPTIONS}
