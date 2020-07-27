#!/bin/bash

set -exo pipefail

terraform init -backend=false
terraform validate
