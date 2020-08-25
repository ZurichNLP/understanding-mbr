#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name

scripts=$base/scripts

data_sub=$base/data/${src}-${trg}
translations_sub_sub=$base/translations/${src}-${trg}/$model_name

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

if [[ -s $evaluations_sub_sub/variations.subnum ]]; then
  continue
fi

# compute subnum variation ranges

python $scripts/eval_subnum.py \
    --ref $data_sub/variations.trg \
    --hyp $translations_sub_sub/variations.trg \
    --num $data_sub/variations.count \
    > $evaluations_sub_sub/variations.subnum

echo "$evaluations_sub_sub/variations.subnum"
cat $evaluations_sub_sub/variations.subnum
