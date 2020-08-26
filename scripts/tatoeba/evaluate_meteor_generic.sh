#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name

source $base/venvs/sockeye3-cpu/bin/activate

scripts=$base/scripts

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

# compute METEOR with internal tokenization

for corpus in dev test; do

    if [[ -s $evaluations_sub_sub/$corpus.beam.meteor ]]; then
      continue
    fi

    # beam translations

    python $scripts/eval_meteor.py \
        --hyp $translations_sub_sub/$corpus.trg \
        --ref $data_sub_sub/$corpus.trg \
        > $evaluations_sub_sub/$corpus.beam.meteor

    echo "$evaluations_sub_sub/$corpus.beam.meteor"
    cat $evaluations_sub_sub/$corpus.beam.meteor

    # single sample translation

    python $scripts/eval_meteor.py \
        --hyp $samples_sub_sub/$corpus.1.trg \
        --ref $data_sub_sub/$corpus.trg \
        > $evaluations_sub_sub/$corpus.single_sample.meteor

    echo "$evaluations_sub_sub/$corpus.single_sample.meteor"
    cat $evaluations_sub_sub/$corpus.single_sample.meteor

    # 30 samples, MBR decoding

    python $scripts/eval_meteor.py \
        --hyp $samples_sub_sub/$corpus.mbr.text \
        --ref $data_sub_sub/$corpus.trg \
        > $evaluations_sub_sub/$corpus.mbr.meteor

    echo "$evaluations_sub_sub/$corpus.mbr.meteor"
    cat $evaluations_sub_sub/$corpus.mbr.meteor

done
