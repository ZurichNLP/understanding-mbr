#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data

python3 $scripts/mbr_decoding.py \
    --inputs $data/toy_samples.{1..10} \
    --output $data/toy_output \
    --risk-function sentence-meteor
