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
beam_sizes="5 10"
nbest_batch_size=10

# fail with non-zero status if there is no model checkpoint,
# to signal to downstream dependencies that they cannot be satisfied

models_sub_sub=$base/models/${src}-${trg}/$model_name

if [[ ! -e $models_sub_sub/params.best ]]; then
    echo "There is no single model checkpoint, file does not exist:"
    echo "$models_sub_sub/params.best"
    exit 1
fi

. $scripts/tatoeba/beam_top_generic.sh

. $scripts/tatoeba/beam_nbest_generic.sh

. $scripts/tatoeba/sample_generic.sh
