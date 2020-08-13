#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
variations=$base/variations

mkdir -p $variations

python3 $scripts/create_variations.py \
    --input-src $data/toy_input \
    --input-trg $data/toy_reference \
    --output-src $variations/toy_variations.src \
    --output-trg $variations/toy_variations.trg \
    --output-variation-counts $variations/toy_variations.count \
    --num-range 10
