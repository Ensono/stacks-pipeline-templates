#!/bin/bash

# This script takes in K8s YAML files and will substitute values into them using
# `envsubst`
# Note: This script existed as `/azDevOps/azure/templates/v2/scripts/yaml-templating.sh`
# in Cycle 2. This is a new version adhering to the Cycle 4 guidelines.

set -exo pipefail

OPTIONS=":a:b:Y:Z"

usage()
{
	set +x
	USAGE=$(cat <<- USAGE_STRING
		Usage: $(basename "${0}") [OPTION]...

		Required Arguments:
			-a inname	The input filename to use
			-b args		Any additonal arguments to pass to 'envsubst'

		Optional Arguments:
			-Y true|false	Whether to 'cat' the output file. Default: false
			-Z outname	The output filename. Default: Strip 'base-' from the inname
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
		a  ) INPUT_TEMPLATE_FILENAME="${OPTARG}";;
		b  ) ADDITIONAL_ENVSUBST_ARGUMENTS="${OPTARG}";;

		# Optional
		Y  ) CAT_OUTPUT_FILE="${OPTARG}";;
		Z  ) OUTPUT_FILENAME="${OPTARG}";;

		\? ) echo "Unknown option: -${OPTARG}" >&2; exit 1;;
		:  ) echo "Missing option argument for -${OPTARG}" >&2; exit 1;;
		*  ) echo "Unimplemented option: -${option}. This is probably unintended." >&2; exit 1;;
	esac
done

if [ -z "${INPUT_TEMPLATE_FILENAME}" ]; then
	echo "-a: Missing input template name" >&2
	exit 1
fi

if [ -z "${ADDITIONAL_ENVSUBST_ARGUMENTS}" ]; then
	ADDITIONAL_ENVSUBST_ARGUMENTS=""
fi

if [ -z "${OUTPUT_FILENAME}" ]; then
	echo "Stripping 'base_' from the beginning of the input filename"
	ORIGINAL_FILENAME="${INPUT_TEMPLATE_FILENAME##*/}"
	REPLACEMENT_FILENAME="${ORIGINAL_FILENAME#"base_"}"
	OUTPUT_FILENAME="${INPUT_TEMPLATE_FILENAME/%${ORIGINAL_FILENAME}/${REPLACEMENT_FILENAME}}"
fi

if [ "${INPUT_TEMPLATE_FILENAME}" == "${OUTPUT_FILENAME}" ]; then
	echo "Either specify an output filename or prefix the input file with 'base_'!" >&2
	exit 2
fi

rm -f "${OUTPUT_FILENAME}"

RETURN_CODE="0"
envsubst \
	-i "${INPUT_TEMPLATE_FILENAME}" \
	-o "${OUTPUT_FILENAME}" \
	-no-unset \
	"${ADDITIONAL_ENVSUBST_ARGUMENTS[@]}" \
|| RETURN_CODE="$?"

echo "Input filename: ${INPUT_TEMPLATE_FILENAME}"
echo "Output filename: ${OUTPUT_FILENAME}"

# Boolean `true` workaround
# CAT_OUTPUT_FILE="$(tr '[:upper:]' '[:lower:]' <<< "${CAT_OUTPUT_FILE}")"
# if [ "${CAT_OUTPUT_FILE}" == 'true' ]; then
# 	cat "${OUTPUT_FILENAME}"
# fi

exit "${RETURN_CODE}"
