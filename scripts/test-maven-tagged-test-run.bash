#!/bin/bash

set -exo pipefail

# Required
GROUP="$1"

# Optional
M2_LOCATION="$2"

if [ -z "$GROUP" ]; then
	echo 'Please specify a group of tests to run, e.g. `Unit`.'
	exit 1
fi

if [ -z "$M2_LOCATION" ]; then
	M2_LOCATION="./.m2"
fi

./mvnw test --no-transfer-progress -Dmaven.repo.local="$M2_LOCATION" --offline -Dgroups="$GROUP"
