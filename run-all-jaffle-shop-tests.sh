#!/bin/bash

if [ -z "$1" ]; then
  echo 'Please provide profile name'
  exit 1
fi

PROFILE="$1"

./run-tests-on-dbt-version.sh "run-jaffle-shop-tests" "$PROFILE" "1.3.3"
./run-tests-on-dbt-version.sh "run-jaffle-shop-tests" "$PROFILE" "1.4.0"
