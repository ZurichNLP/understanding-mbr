#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
tools=$base/tools
variations=$base/variations

mkdir -p $variations

python3 $tools/variation-generation/main.py \
    --bitext $data/toy_input \
    --numvar 10 \
    --output $variations/toy_input
