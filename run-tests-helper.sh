#!/bin/bash

function run_tests() {
  local TEST_SUITE=$1
  local PROFILE=$2

  if [ "$PROFILE" == "postgres" ]; then
    VERSIONS="1.3.4 1.4.6 1.5.4 1.7.4"
  elif [ "$PROFILE" == "bigquery" ]; then
    VERSIONS="1.7.2"
  elif [ "$PROFILE" == "snowflake" ]; then
    VERSIONS="1.7.1"
  else
    echo "Invalid profile name: $PROFILE"
    exit 1
  fi

  if [ -z "$TEST_SUITE" ]; then
    echo 'Please provide test suite name'
    exit 1
  fi

  if [ -z "$PROFILE" ]; then
    echo 'Please provide profile name'
    exit 1
  fi

  if [ -z "$VERSIONS" ]; then
    echo 'Please provide versions to test'
    exit 1
  fi

  for DBT_VERSION in $VERSIONS; do
    ./run-tests-on-dbt-version.sh "$TEST_SUITE" "$PROFILE" "$DBT_VERSION"
  done
}
