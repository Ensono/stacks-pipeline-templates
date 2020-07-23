#!/bin/bash

set -exo pipefail

# Optional
M2_LOCATION="$1"

if [ -z "$M2_LOCATION" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw dependency:go-offline -Dmaven.repo.local="$M2_LOCATION" --no-transfer-progress
./mvnw process-resources --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION"
