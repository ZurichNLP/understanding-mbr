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

. $scripts/tatoeba/beam_top_generic.sh

. $scripts/tatoeba/beam_nbest_generic.sh

. $scripts/tatoeba/sample_generic.sh
