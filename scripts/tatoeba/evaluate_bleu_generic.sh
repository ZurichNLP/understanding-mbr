#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name

source $base/venvs/sockeye3-cpu/bin/activate

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mbr=$base/mbr
mbr_sub=$mbr/${src}-${trg}
mbr_sub_sub=$mbr_sub/$model_name

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

# compute case-sensitive BLEU on detokenized data

for corpus in dev test; do

    if [[ -s $evaluations_sub_sub/$corpus.beam.bleu ]]; then
      continue
    fi

    # beam translations

    cat $translations_sub_sub/$corpus.trg | sacrebleu $data_sub_sub/$corpus.trg > $evaluations_sub_sub/$corpus.beam.bleu

    echo "$evaluations_sub_sub/$corpus.beam.bleu"
    cat $evaluations_sub_sub/$corpus.beam.bleu

    # single sample translation

    cat $samples_sub_sub/$corpus.1.trg | sacrebleu $data_sub_sub/$corpus.trg > $evaluations_sub_sub/$corpus.single_sample.bleu

    echo "$evaluations_sub_sub/$corpus.single_sample.bleu"
    cat $evaluations_sub_sub/$corpus.single_sample.bleu

    # 30 samples, MBR decoding

    cat $samples_sub_sub/$corpus.mbr.text | sacrebleu $data_sub_sub/$corpus.trg > $evaluations_sub_sub/$corpus.mbr.bleu

    echo "$evaluations_sub_sub/$corpus.mbr.bleu"
    cat $evaluations_sub_sub/$corpus.mbr.bleu

done
