#!/bin/bash
VENV="venv-$1/bin/activate"

if [[ ! -f $VENV ]]; then
    python3 -m venv venv-$1
    # the virtualenv is dynamically determined from the first argument to the
    # run test script to we are deliberately working around a shellcheck warning
    # with the directive below
    # shellcheck source=/dev/null
    . "${VENV}"

    pip install --upgrade pip setuptools
    pip install --pre "dbt-$1"
fi

# the virtualenv is dynamically determined from the first argument to the
# run test script to we are deliberately working around a shellcheck warning
# with the directive below
# shellcheck source=/dev/null
. "${VENV}"

cd integration-tests || exit

if [[ ! -e ~/.dbt/profiles.yml ]]; then
    mkdir -p ~/.dbt
    cp ci/profiles.yml ~/.dbt/profiles.yml
fi

dbt deps --target $1
dbt test --target $1 --models tag:unit-test
