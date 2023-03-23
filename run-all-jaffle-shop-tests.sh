#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo 'Please provide profile name'
  exit 1
fi

PROFILE="$1"

# Source the script that contains the run_tests function and versions
source ./run-tests-helper.sh

run_tests "run-jaffle-shop-tests" "$PROFILE"
