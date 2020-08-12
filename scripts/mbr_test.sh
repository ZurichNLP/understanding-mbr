#! /bin/bash

python3 mbr_decoding.py \
    --inputs t.{1..10} \
    --output o \
    --risk-function sentence-meteor