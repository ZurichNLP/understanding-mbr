#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $dry_run
# $corpora

base=$1
src=$2
trg=$3
model_name=$4
dry_run=$5
corpora=$6

scripts=$base/scripts

if [[ $dry_run == "true" ]]; then
    source $base/venvs/sockeye3-cpu/bin/activate
else
    source $base/venvs/sockeye3/bin/activate
fi

seeds="1 2"

. $scripts/tatoeba/beam_top_generic.sh

. $scripts/tatoeba/beam_nbest_generic.sh

. $scripts/tatoeba/sample_generic.sh
