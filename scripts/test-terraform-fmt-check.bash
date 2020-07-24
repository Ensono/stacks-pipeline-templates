#!/bin/bash

set -exo pipefail

terraform fmt -diff -check -recursive
