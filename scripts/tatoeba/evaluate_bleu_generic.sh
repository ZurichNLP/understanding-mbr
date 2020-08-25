#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name

data_sub=$base/data/${src}-${trg}
translations_sub_sub=$base/translations/${src}-${trg}/$model_name

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

for corpus in dev test; do

    if [[ -s $evaluations_sub_sub/$corpus.bleu ]]; then
      continue
    fi

    # compute case-sensitive BLEU on detokenized data

    cat translations_sub_sub/$corpus.trg | sacrebleu data_sub/$corpus.trg > $evaluations_sub_sub/$corpus.bleu

    echo "$evaluations_sub_sub/$corpus.bleu"
    cat $evaluations_sub_sub/$corpus.bleu

done
