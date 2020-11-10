#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

venvs=$base/venvs

export TMPDIR="/var/tmp"

mkdir -p $venvs

echo "pyenv known versions"

pyenv versions

echo "Executing: pyenv local 3.6.12"

pyenv local 3.6.12

virtualenv -p python3 $venvs/fairseq3

# different venv for Sockeye

virtualenv -p python3 $venvs/sockeye3

# different venv for Sockeye CPU

virtualenv -p python3 $venvs/sockeye3-cpu
