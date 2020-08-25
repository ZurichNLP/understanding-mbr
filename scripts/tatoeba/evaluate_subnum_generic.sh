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

# compute subnum variation ranges

# beam translations

python $scripts/eval_subnum.py \
    --ref $data_sub_sub/test.trg \
    --hyp $translations_sub_sub/variations.trg \
    --num $data_sub_sub/variations.count \
    > $evaluations_sub_sub/variations.beam.subnum

echo "$evaluations_sub_sub/variations.beam.subnum"
cat $evaluations_sub_sub/variations.beam.subnum

# MBR decoding

python $scripts/eval_subnum.py \
    --ref $data_sub_sub/test.trg \
    --hyp $samples_sub_sub/variations.mbr.text \
    --num $data_sub_sub/variations.count \
    > $evaluations_sub_sub/variations.beam.subnum

echo "$evaluations_sub_sub/variations.beam.subnum"
cat $evaluations_sub_sub/variations.beam.subnum
