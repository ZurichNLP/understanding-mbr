#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
variations=$base/variations

mkdir -p $variations

variations_sub=$variations/toy

mkdir -p $variations_sub

python $scripts/create_variations.py \
    --input-src $data/toy_input \
    --input-trg $data/toy_reference \
    --output-src $variations_sub/toy_variations.src \
    --output-trg $variations_sub/toy_variations.trg \
    --output-variation-counts $variations_sub/toy_variations.count \
    --num-range 10
