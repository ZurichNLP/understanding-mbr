#! /bin/bash

# calling script needs to set:

# $input
# $output_prefix
# $base

scripts=$base/scripts

models=$base/models
models_sub=$models/fairseq-wmt19-de-en

for seed in {1..30}; do

  cat $input | CUDA_VISIBLE_DEVICES=1 python $scripts/translate.py \
      --method sampling \
      --nbest-size 1 \
      --model-folder $models_sub/"wmt19.de-en.joined-dict.ensemble" \
      --checkpoint "model1.pt" \
      --bpe-codes $models_sub/"wmt19.de-en.joined-dict.ensemble/bpecodes" \
      --bpe-method "fastbpe" \
      --tokenizer-method "moses" \
      --seed $seed \
      > $output_prefix.$seed

      cat $output_prefix.$seed | cut -f3 > $output_prefix.text.$seed
done
