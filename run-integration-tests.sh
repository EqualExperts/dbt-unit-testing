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

dbt deps --target "$PROFILE"

dbt run-operation --target "$PROFILE" create_schema --args '{relation: default_schema_1 }'
dbt run-operation --target "$PROFILE" create_schema --args '{relation: default_schema_2 }'
dbt run-operation --target "$PROFILE" create_schema --args '{relation: snapshots }'

# create seeds in the database
dbt seed --target "$PROFILE" --select seeds/real_seeds
# run tests with no database dependency
dbt test --target "$PROFILE" --select tag:unit-test,tag:"$PROFILE" --exclude tag:db-dependency

# create sources in the database
dbt seed --target "$PROFILE" --select seeds/existing_sources
# create models in the database for tests that depends on database models
dbt run --target "$PROFILE" --select tag:add-to-database

# run tests with database dependency
dbt test --target "$PROFILE" --select tag:unit-test,tag:"$PROFILE",tag:db-dependency
