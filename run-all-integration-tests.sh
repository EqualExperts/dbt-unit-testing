#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo 'Please provide profile name'
  exit 1
fi

PROFILE="$1"


./run-tests-on-dbt-version.sh "run-integration-tests" "$PROFILE" "1.3.0"
./run-tests-on-dbt-version.sh "run-integration-tests" "$PROFILE" "1.4.0"
