#!/bin/bash

# Installs (most) maven dependencies and processes them.

set -exo pipefail

OPTIONS=":K:R:F:S:Z:T:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
		  -T location	Optional maven settings security  file. Default: \`./.mvn/settings-security.xml\`
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
while getopts "${OPTIONS}" flag
do
    case "${flag}" in
        e) echo "Got flag -e";;
        d) echo "Got flag -d";;
        f) echo "Got flag -f with respective option ${OPTARG}";;
    esac
done

# Detect `--help`, show usage and exit
i=1 ;
for var in "$@"; do
	if [ "${var}" == '--help' ]; then
		usage
		exit 0
	fi
	 echo "gpg key id - $i: $GPG_KEY_ID ";
   i=$((i + 1));
done

while getopts "${OPTIONS}" option
do
	case "${option}" in
        # Required private signing key
        K  ) GPG_KEY_ID="${OPTARG}";;
        # Optional
        R  ) ALT_DEPLOYMENT_REPOSITORY="${OPTARG}";;
        F  ) POM_FILE="${OPTARG}";;
        S  ) SETTINGS_LOCATION="${OPTARG}";;
        Z  ) M2_LOCATION="${OPTARG}";;
        T  ) SETTINGS_SECURITY_LOCATION="${OPTARG}";;


        \? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
        :  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
        *  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
    esac
done
echo "gpg key : $GPG_KEY_ID";
echo "SETTINGS_SECURITY_LOCATION: $SETTINGS_SECURITY_LOCATION";


if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

MAVEN_OPTIONS=" -Dmaven.test.skip=true -Dmaven.repo.local=${M2_LOCATION}  --no-transfer-progress "

if [ "${SETTINGS_LOCATION}" ]; then
	MAVEN_OPTIONS+=" --settings ${SETTINGS_LOCATION} "
fi
if [ "${SETTINGS_SECURITY_LOCATION}" ]; then
	MAVEN_OPTIONS+=" -Dsettings.security=${SETTINGS_SECURITY_LOCATION} "
fi

if [ "${POM_FILE}" ]; then
	MAVEN_OPTIONS+=" -f  ${POM_FILE} "
fi

if [ "${GPP_KEY_ID}" ]; then
	MAVEN_OPTIONS+=" -Darguments=-Dgpg.keyname=${GPG_KEY_ID} "
fi

if [ "${ALT_DEPLOYMENT_REPOSITORY}" ]; then
	MAVEN_OPTIONS+=" -DaltDeploymentRepository=${ALT_DEPLOYMENT_REPOSITORY} "
fi

./mvnw deploy -P release-sign-artifacts ${MAVEN_OPTIONS} -X
