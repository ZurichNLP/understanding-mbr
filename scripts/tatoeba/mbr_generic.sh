#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

base=$1
src=$2
trg=$3
model_name=$4

scripts=$base/scripts

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mkdir -p $samples_sub_sub

source $base/venvs/sockeye3/bin/activate

# sampling translation

for corpus in dev test variations; do

    deactivate
    source $base/venvs/sockeye3-cpu/bin/activate

    # MBR

    python $scripts/mbr_decoding.py \
        --inputs $samples_sub_sub/$corpus.{1..30}.trg \
        --output $samples_sub_sub/$corpus.mbr \
        --utility-function sentence-meteor

    cat $samples_sub_sub/$corpus.mbr | cut -f2 > $samples_sub_sub/$corpus.mbr.text

done
