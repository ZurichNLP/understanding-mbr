#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
models=$base/models
models_sub=$models/fairseq-wmt19-de-en

samples=$base/samples
translations=$base/translations

mkdir -p $translations
mkdir -p $samples

for seed in {1..30}; do

  cat $data/toy_input | CUDA_VISIBLE_DEVICES=1 python $scripts/translate.py \
      --method sampling \
      --nbest-size 1 \
      --model-folder $models_sub/"wmt19.de-en.joined-dict.ensemble" \
      --checkpoint "model1.pt" \
      --bpe-codes $models_sub/"wmt19.de-en.joined-dict.ensemble/bpecodes" \
      --bpe-method "fastbpe" \
      --tokenizer-method "moses" \
      --seed $seed \
      > $samples/toy_samples.$seed

      cat $samples/toy_samples.$seed | cut -f3 > $samples/toy_samples.text_only.$seed
done

cat $data/toy_input | CUDA_VISIBLE_DEVICES=1 python $scripts/translate.py \
      --method beam \
      --nbest-size 1 \
      --beam-size 5 \
      --model-folder $models_sub/"wmt19.de-en.joined-dict.ensemble" \
      --checkpoint "model1.pt" \
      --bpe-codes $models_sub/"wmt19.de-en.joined-dict.ensemble/bpecodes" \
      --bpe-method "fastbpe" \
      --tokenizer-method "moses" \
       > $translations/toy_translation
