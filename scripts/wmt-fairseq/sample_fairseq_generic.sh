#! /bin/bash

# calling script needs to set:

# $input
# $output_prefix
# $base

scripts=$base/scripts

models=$base/models
models_sub=$models/fairseq-wmt19-de-en

if [[ -f $output_prefix.mbr.text ]]; then
    echo "File exists: $output_prefix.mbr.text"
    echo "Skipping."
else

    for seed in {1..30}; do

      if [[ -f $output_prefix.$seed ]]; then

        num_lines_input=`cat $input | wc -l`
        num_lines_output=`cat $output_prefix.$seed | wc -l`

        if [[ $num_lines_input == $num_lines_output ]]; then
          echo "output exists and number of lines are equal to input:"
          echo "$num_lines_input == $num_lines_output"
          echo "Skipping."
          continue
        fi
      fi

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

    # find best MBR sample

    python $scripts/mbr_decoding.py \
        --inputs $output_prefix.text.{1..30} \
        --output $output_prefix.mbr \
        --utility-function sentence-meteor \
        --num-workers 12

    cat $output_prefix.mbr | cut -f2 > $output_prefix.mbr.text

fi

