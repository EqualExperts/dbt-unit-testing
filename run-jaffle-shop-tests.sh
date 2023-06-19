#!/bin/bash

if [ -z "$1" ]; then
  echo 'Please provide profile name'
  exit 1
fi

PROFILE="$1"

cd jaffle-shop || exit

if [[ ! -e ~/.dbt/profiles.yml ]]; then
  mkdir -p ~/.dbt
  cp ci/profiles.yml ~/.dbt/profiles.yml
fi

dbt deps --target "$PROFILE"
dbt test --target "$PROFILE" --models tag:unit-test, --exclude tag:db-dependency
# create seeds in the database
dbt seed --target "$PROFILE"
# run tests that leverages from the created sources
dbt test --target "$PROFILE" --models tag:unit-test,tag:db-dependency
