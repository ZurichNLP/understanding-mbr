#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
models=$base/models
models_sub=$models/fairseq-wmt19-de-en

for seed in {1..10}; do

  cat $data/toy_input | CUDA_VISIBLE_DEVICES=1 python $scripts/translate.py \
      --method sampling \
      --nbest-size 1 \
      --model-folder $models_sub/"model/wmt19.de-en.joined-dict.ensemble" \
      --checkpoint "model1.pt" \
      --bpe-codes $models_sub/"model/wmt19.de-en.joined-dict.ensemble/bpecodes" \
      --bpe-method "fastbpe" \
      --tokenizer-method "moses" \
      --seed $seed \
      > $data/toy_samples.$seed
done
