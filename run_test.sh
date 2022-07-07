#!/bin/bash

if [ -z "$1" ]; then
  echo 'Please provide profile name'
  exit 1
fi

VENV="venv-$1/bin/activate"

if [[ ! -f $VENV ]]; then
  python3 -m venv "venv-$1"
  . $VENV

  pip install --upgrade pip setuptools
  pip install --pre "dbt-$1"
fi

. $VENV
cd integration-tests || exit

if [[ ! -e ~/.dbt/profiles.yml ]]; then
  mkdir -p ~/.dbt
  cp ci/profiles.yml ~/.dbt/profiles.yml
fi

dbt deps --target "$1"

# create seeds in the database
dbt seed --target "$1" --select seeds/real_seeds
# run tests with no database dependency
dbt test --target "$1" --select tag:unit-test,tag:"$1" --exclude tag:db-dependency

# create sources in the database
dbt seed --target "$1" --select seeds/existing_sources
# create models in the database for tests that depends on database models
dbt run --target "$1" --select models/complex_hierarchy
# run tests with database dependency
dbt test --target "$1" --select tag:unit-test,tag:"$1",tag:db-dependency
