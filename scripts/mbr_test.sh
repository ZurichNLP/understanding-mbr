#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

samples=$base/samples

python3 $scripts/mbr_decoding.py \
    --inputs $samples/toy/toy_samples.text.{1..30} \
    --output $samples/toy/mbr \
    --utility-function sentence-meteor \
    --num-workers 2
