#! /bin/bash

for seed in 1 2 3; do

  cat t | CUDA_VISIBLE_DEVICES=1 python translate.py \
      --method sampling \
      --nbest-size 10 \
      --model-folder "model/wmt19.de-en.joined-dict.ensemble" \
      --checkpoint "model1.pt" \
      --bpe-codes "model/wmt19.de-en.joined-dict.ensemble/bpecodes" \
      --bpe-method "fastbpe" \
      --tokenizer-method "moses" \
      --seed $seed
done
