#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo 'Please provide test script to run'
  exit 1
fi

if [ -z "$2" ]; then
  echo 'Please provide profile name'
  exit 1
fi

if [ -z "$3" ]; then
  echo 'Please provide dbt version'
  exit 1
fi

TEST_SCRIPT="$1"
PROFILE="$2"
DBT_VERSION=$3

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
VENV_NAME="venv-$PROFILE"
VENV_FOLDER="$SCRIPT_DIR/$VENV_NAME"

rm -rf "$VENV_FOLDER"
python3 -m venv "$VENV_FOLDER"
source "$VENV_FOLDER/bin/activate"

pip install --upgrade pip setuptools
pip install "dbt-$PROFILE==$DBT_VERSION"

if [ "$DBT_VERSION" = "1.3.1" ]; then
  cp integration-tests/packages_1_3_1.yml integration-tests/packages.yml
  cp -r integration-tests/tests/fixtures/metrics integration-tests/models/
else
  cp integration-tests/packages_1_2_0.yml integration-tests/packages.yml
fi

"$SCRIPT_DIR/$TEST_SCRIPT.sh" "$PROFILE"
