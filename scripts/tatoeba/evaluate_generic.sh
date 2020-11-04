#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name
# $utility_functions
# $corpora

base=$1
src=$2
trg=$3
model_name=$4
utility_functions=$5
corpora=$6

scripts=$base/scripts

seeds="1 2"

. $scripts/tatoeba/evaluate_bleu_chrf_generic.sh

. $scripts/tatoeba/evaluate_meteor_generic.sh

# does not seem worth it - do not evaluate for now

# . $scripts/tatoeba/evaluate_subnum_generic.sh
