#!/bin/bash

set -exo pipefail

# Optional
M2_LOCATION="$1"

if [ -z "$M2_LOCATION" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw compile --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION" --offline
./mvnw process-test-resources --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION" --offline
./mvnw test-compile --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION" # TODO: Maybe this should be run offline?
