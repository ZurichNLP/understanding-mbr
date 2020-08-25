#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
variations=$base/variations

mkdir -p $variations

mkdir -p $data/toy

echo "Bei einem Unfall eines Reisebusses mit 43 Senioren als Fahrgästen sind am Donnerstag in Krummhörn (Landkreis Aurich) acht Menschen verletzt worden." > $data/toy/toy_input

echo "On Thursday, an accident involving a coach carrying 43 elderly people in Krummhörn (district of Aurich) led to eight people being injured." > $data/toy/toy_reference

data_sub=$data/toy
variations_sub=$variations/toy

mkdir -p $variations_sub

python3 $scripts/create_variations.py \
    --input-src $data_sub/toy_input \
    --input-trg $data_sub/toy_reference \
    --output-src $variations_sub/toy_variations.src \
    --output-trg $variations_sub/toy_variations.trg \
    --output-variation-counts $variations_sub/toy_variations.count \
    --num-range 10
