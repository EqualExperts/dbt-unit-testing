#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo 'Please provide profile name'
  exit 1
fi

PROFILE=$1

cd integration-tests || exit

if [[ ! -e ~/.dbt/profiles.yml ]]; then
  mkdir -p ~/.dbt
  cp ci/profiles.yml ~/.dbt/profiles.yml
fi

EXCLUDE_STR=''
FLAG_VERSION=''
DBT_VERSION=$(pip freeze | grep dbt-core | cut -d '=' -f 3)

if [ "$DBT_VERSION" == "1.2.0" ]; then
  EXCLUDE_STR=',tag:metrics-tests'
  FLAG_VERSION='--no-version-check'
fi

echo 1
dbt deps --target "$PROFILE"

# create seeds in the database
echo 2
dbt seed --target "$PROFILE" --select seeds/real_seeds --exclude metrics
# run tests with no database dependency
echo 3
dbt test --target "$PROFILE" --select tag:unit-test,tag:"$PROFILE" --exclude tag:db-dependency"$EXCLUDE_STR"

# create sources in the database
echo 4
dbt seed --target "$PROFILE" --select seeds/existing_sources
# create models in the database for tests that depends on database models

echo 5
dbt run --target "$PROFILE" --select models/complex_hierarchy
# run tests with database dependency
echo 6
dbt test --target "$PROFILE" --select tag:unit-test,tag:"$PROFILE",tag:db-dependency"$EXCLUDE_STR"
