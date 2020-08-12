#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

translations=$base/translations

python3 $scripts/mbr_decoding.py \
    --inputs $translations/toy_samples.{1..30} \
    --output $translations/toy_output \
    --risk-function sentence-meteor
