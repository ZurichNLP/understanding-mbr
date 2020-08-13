#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

venvs=$base/venvs

export TMPDIR="/var/tmp"

mkdir -p $venvs

virtualenv -p python3 $venvs/fairseq3
