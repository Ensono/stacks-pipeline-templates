#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

OPTIONS=":U:P:G:R:F:S:Z:R:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -U location	OSSRH_JIRA_ID
		  -P location	OSSRH_JIRA_PASSWORD
			-K id user for signing release

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
        # Required private signing key
        G  ) GPG_SIGNING_KEY_ID="${OPTARG}";;
        U  ) OSSRH_JIRA_ID="${OPTARG}";;
        P  ) OSSRH_JIRA_PASSWORD="${OPTARG}";;
        F  ) POM_FILE="${OPTARG}";;
        Z  ) M2_LOCATION="${OPTARG}";;


        # Optional
        R  ) ALT_DEPLOYMENT_REPOSITORY="${OPTARG}";;
        S  ) SETTINGS_LOCATION="${OPTARG}";;


        \? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
        :  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
        *  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
    esac
done

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

MAVEN_OPTIONS=" -Dmaven.test.skip=true -Dmaven.repo.local=${M2_LOCATION}  --no-transfer-progress "

if [ "${SETTINGS_LOCATION}" ]; then
	MAVEN_OPTIONS+=" --settings ${SETTINGS_LOCATION} "
fi

if [ "${OSSRH_JIRA_ID}" ]; then
  MAVEN_OPTIONS+=" -Dossrh.jira.id=${OSSRH_JIRA_ID} -Dossrh.jira.password=${OSSRH_JIRA_PASSWORD} "
fi
	MAVEN_OPTIONS+=" -Dsettings.security=${SETTINGS_SECURITY_LOCATION} "

if [ "${POM_FILE}" ]; then
	MAVEN_OPTIONS+=" -f  ${POM_FILE} "
fi

if [ -z "${GPG_SIGNING_KEY_ID}" ]; then
	MAVEN_OPTIONS+=" -Dgpg.keyname=092B09487E026B19B283373689DE10D4E6D9FEDA "
fi

if [ "${ALT_DEPLOYMENT_REPOSITORY}" ]; then
	MAVEN_OPTIONS+=" -DaltDeploymentRepository=${ALT_DEPLOYMENT_REPOSITORY} "
fi
./mvnw clean deploy -P release-sign-artifacts ${MAVEN_OPTIONS} -X
./mvnw nexus-staging:release -P release-sign-artifacts ${MAVEN_OPTIONS} -X