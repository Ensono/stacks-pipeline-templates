#!/bin/bash

# Runs the OWASP Dependency Check

set -exo pipefail

OPTIONS=":V:W:X:Y:Z:"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Optional Arguments:
		  -V true|false	Whether to enable the dotnet analyser or not
		  -W location	A location for the OWASP database to be stored under
		  -X key	An API key for the NVD Databases (NOTE: This will be very slow without one, they can be requested here: https://nvd.nist.gov/developers/request-an-api-key)
		  -Y true|false	Whether to fail the build or not on vulnerabilities. Default: false
		  -Z location	Optional maven cache directory. Default: './.m2'
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
		V  ) DOTNET_ANALYSER_ENABLED="${OPTARG}";;
		W  ) DATABASE_DIRECTORY="${OPTARG}";;
		X  ) NVD_API_KEY="${OPTARG}";;
		Y  ) FAIL_BUILD_ON_VULNERABILITY="${OPTARG}";;
		Z  ) M2_LOCATION="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

declare -a EXTRA_OWASP_ARGUMENTS

if [ -z "${M2_LOCATION}" ]; then
	M2_LOCATION="./.m2"
fi

if [ -z "${FAIL_BUILD_ON_VULNERABILITY}" ]; then
	FAIL_BUILD_ON_VULNERABILITY="false"
fi

if [ -z "${DOTNET_ANALYSER_ENABLED}" ]; then
	DOTNET_ANALYSER_ENABLED="false"
fi

if [ ! -z "${DATABASE_DIRECTORY}" ]; then
	EXTRA_OWASP_ARGUMENTS+=("-DdataDirectory=${DATABASE_DIRECTORY}")
fi

if [ ! -z "${NVD_API_KEY}" ]; then
	EXTRA_OWASP_ARGUMENTS+=("-DnvdApiKey=${NVD_API_KEY}")
fi

FAIL_BUILD_ON_VULNERABILITY="$(tr '[:upper:]' '[:lower:]' <<< "${FAIL_BUILD_ON_VULNERABILITY}")"
if [ "${FAIL_BUILD_ON_VULNERABILITY}" != "true" ]; then
	FAIL_BUILD_ON_VULNERABILITY="11"
else
	FAIL_BUILD_ON_VULNERABILITY="0"
fi

./mvnw org.owasp:dependency-check-maven:check \
	--no-transfer-progress \
	-Powasp-dependency-check \
	-Dmaven.repo.local="${M2_LOCATION}" \
	-Dsun.jnu.encoding=UTF-8 \
	-Dfile.encoding=UTF-8 \
	-DfailBuildOnCVSS="${FAIL_BUILD_ON_VULNERABILITY}" \
	-DassemblyAnalyzerEnabled="${DOTNET_ANALYSER_ENABLED}" \
	"${EXTRA_OWASP_ARGUMENTS[@]}"
