#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
translations=$base/translations

python3 $scripts/mbr_decoding.py \
    --inputs $translations/toy_samples.{1..10} \
    --output $translations/toy_output \
    --risk-function sentence-meteor
