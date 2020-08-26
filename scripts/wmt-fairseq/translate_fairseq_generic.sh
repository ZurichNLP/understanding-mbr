#! /bin/bash

# calling script needs to set:

# $input
# $output
# $base
# $nbest_size
# $beam_size

scripts=$base/scripts/wmt-fairseq

models=$base/models
models_sub=$models/fairseq-wmt19-de-en

if [[ -f $output.top ]]; then
  echo "Outfile exists: $output.top"
  echo "Skipping."
else

  cat $input | CUDA_VISIBLE_DEVICES=1 python $scripts/translate.py \
        --method beam \
        --nbest-size $nbest_size \
        --beam-size $beam_size \
        --model-folder $models_sub/"wmt19.de-en.joined-dict.ensemble" \
        --checkpoint "model1.pt" \
        --bpe-codes $models_sub/"wmt19.de-en.joined-dict.ensemble/bpecodes" \
        --bpe-method "fastbpe" \
        --tokenizer-method "moses" \
         > $output.nbest

  cat $output.nbest | python $scripts/extract_top.py > $output.top

fi
