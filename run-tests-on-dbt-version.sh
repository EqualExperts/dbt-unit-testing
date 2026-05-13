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

echo "Running $TEST_SCRIPT on dbt $DBT_VERSION with profile $PROFILE"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
VENV_NAME="venv-$PROFILE"
VENV_FOLDER="$SCRIPT_DIR/$VENV_NAME"

DBT_MINOR=$(echo "$DBT_VERSION" | awk -F. '{print $1 "_" $2}')
case "$DBT_MINOR" in
  1_3) DEFAULT_PYTHON=python3.10 ;;
  1_4|1_5|1_7) DEFAULT_PYTHON=python3.11 ;;
  *) DEFAULT_PYTHON=python3 ;;
esac
PYTHON_VAR="PYTHON_${DBT_MINOR}"
PYTHON_BIN="${!PYTHON_VAR:-${PYTHON:-$DEFAULT_PYTHON}}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Error: '$PYTHON_BIN' (selected for dbt $DBT_VERSION) not found on PATH."
  echo "Install it (e.g. via pyenv: 'pyenv install ${PYTHON_BIN#python}')"
  echo "or override with $PYTHON_VAR=<path> (per-version) or PYTHON=<path> (global)."
  exit 1
fi

rm -rf "$VENV_FOLDER"
"$PYTHON_BIN" -m venv "$VENV_FOLDER"

source "$VENV_FOLDER/bin/activate"

pip install --upgrade pip setuptools
pip install "dbt-$PROFILE==$DBT_VERSION"

"$SCRIPT_DIR/$TEST_SCRIPT.sh" "$PROFILE" "$DBT_VERSION"
