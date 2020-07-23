#!/bin/bash

set -exo pipefail

./mvnw jacoco:report --no-transfer-progress -Dmaven.repo.local=./.m2 --offline
