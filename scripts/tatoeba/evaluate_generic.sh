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

seeds="1 2"
corpora="dev test" # variations

. $scripts/tatoeba/evaluate_bleu_generic.sh

. $scripts/tatoeba/evaluate_meteor_generic.sh

# does not seem worth it - do not evaluate for now

# . $scripts/tatoeba/evaluate_subnum_generic.sh
