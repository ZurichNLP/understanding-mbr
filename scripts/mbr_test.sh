#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

samples=$base/samples

python3 $scripts/mbr_decoding.py \
    --inputs $samples/toy_samples.text_only.{1..30} \
    --output $samples/toy_output \
    --utility-function sentence-meteor
