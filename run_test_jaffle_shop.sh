#!/bin/bash
VENV="venv-$1/bin/activate"

if [[ ! -f $VENV ]]; then
    python3 -m venv venv-$1
    . $VENV

    pip install --upgrade pip setuptools
    pip install --pre "dbt-$1"
fi

. $VENV
cd jaffle-shop

if [[ ! -e ~/.dbt/profiles.yml ]]; then
    mkdir -p ~/.dbt
    cp ci/profiles.yml ~/.dbt/profiles.yml
fi

dbt deps --target $1
dbt test --target $1 --models tag:unit-test,tag:no-db-dependency
# create seeds in the database
dbt seed --target $1
# run tests that leverages from the created sources
dbt test --target $1 --models tag:unit-test,tag:db-dependency
