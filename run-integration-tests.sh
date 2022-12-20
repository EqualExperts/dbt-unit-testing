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

DBT_VERSION=$(pip freeze | grep dbt-core | cut -d '=' -f 3)

if [ "$DBT_VERSION" = "1.3.1" ]; then
    # Force dbt==1.3.1 to be used instead of 1.2.0
    pip install -U dbt-postgres==1.3.1
fi

dbt deps --target "$PROFILE"

# create seeds in the database
dbt seed --target "$PROFILE" --select seeds/real_seeds

# run tests with no database dependency
dbt test --target "$PROFILE" --select tag:unit-test,tag:"$PROFILE" --exclude tag:db-dependency

# create sources in the database
dbt seed --target "$PROFILE" --select seeds/existing_sources

# create models in the database for tests that depends on database models
dbt run --target "$PROFILE" --select models/complex_hierarchy

# run tests with database dependency
dbt test --target "$PROFILE" --select tag:unit-test,tag:"$PROFILE",tag:db-dependency

# test metrics
dbt test --target "$PROFILE" --select tag:unit-test,tag:metrics-test

dbt clean --target "$PROFILE"

if [ -d "models/metrics" ]; then
    # If metrics remains in models then the other tests will break on their turn
    rm -rf models/metrics
fi
