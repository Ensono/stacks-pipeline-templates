#!/bin/bash

set -exo pipefail

# Required
SONAR_HOST_URL="$1"
SONAR_PROJECT_NAME="$2"
SONAR_PROJECT_KEY="$3"
SONAR_TOKEN="$4"
SONAR_ORGANIZATION="$5"
BUILD_NUMBER="$6"
SOURCE_BRANCH_REF="$7"

# Optional
SONAR_COMMAND="$8"
TARGET_BRANCH_REF="$9"
PULL_REQUEST_NUMBER="${10}"

function strip_refs()
{
	local BRANCH_REF="$1"

	RETURN_BRANCH="$(sed -e "s%^refs/\(heads\|tags\)/%%" <<< $BRANCH_REF)"
}

strip_refs "${SOURCE_BRANCH_REF}"
SOURCE_BRANCH=$RETURN_BRANCH

strip_refs "${TARGET_BRANCH_REF}"
TARGET_BRANCH=$RETURN_BRANCH

if [ -z "${PULL_REQUEST_NUMBER}" ]; then
	EXTRA_SONAR_ARGUMENTS="-Dsonar.branch.name='${SOURCE_BRANCH}'"
	EXTRA_SONAR_ARGUMENTS="${EXTRA_SONAR_ARGUMENTS} -Dsonar.branch.target='${TARGET_BRANCH}'"
else
	PROVIDER_LOWERCASED="$(tr '[:upper:]' '[:lower:]' <<< "${{ parameters.sonar_pullrequest_provider }}")"

	EXTRA_SONAR_ARGUMENTS="-Dsonar.pullrequest.key='${{ parameters.pullrequest_number }}'"
	EXTRA_SONAR_ARGUMENTS="${EXTRA_SONAR_ARGUMENTS} -Dsonar.pullrequest.branch='${SOURCE_BRANCH}'"
	EXTRA_SONAR_ARGUMENTS="${EXTRA_SONAR_ARGUMENTS} -Dsonar.pullrequest.provider='${PROVIDER_LOWERCASED}'"
	EXTRA_SONAR_ARGUMENTS="${EXTRA_SONAR_ARGUMENTS} -Dsonar.pullrequest.base='${TARGET_BRANCH}'"

	if [ "$PROVIDER_LOWERCASED" == 'github' ]; then
		EXTRA_SONAR_ARGUMENTS="${EXTRA_SONAR_ARGUMENTS} -Dsonar.pullrequest.github.repository='${{ parameters.sonar_remote_repo }}'"
	fi
fi
