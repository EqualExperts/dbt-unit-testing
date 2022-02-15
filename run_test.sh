#!/bin/bash
VENV="venv/bin/activate"

if [[ ! -f $VENV ]]; then
    python3 -m venv venv
    . $VENV

    pip install --upgrade pip setuptools
    pip install --pre "dbt-$1"
fi

. $VENV
cd integration-tests

if [[ ! -e ~/.dbt/profiles.yml ]]; then
    mkdir -p ~/.dbt
    cp ci/profiles.yml ~/.dbt/profiles.yml
fi

dbt deps --target $1
dbt run --target $1 --models mock-staging-tables
dbt run --target $1 --models transform product
dbt test --target $1 --models tag:unit-test