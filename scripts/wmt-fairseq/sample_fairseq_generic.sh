#! /bin/bash

# calling script needs to set:

# $input
# $output_prefix
# $base

scripts=$base/scripts/wmt-fairseq

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

    # divide inputs into up to 16 parts

    mkdir -p $base/samples/wmt/sample_parts

    for seed in {1..30}; do
        python $base/scripts/split.py --parts 16 --input $output_prefix.text.$seed
    done

    for part in {1..16}; do

        python $base/scripts/mbr_decoding.py \
            --inputs $output_prefix.text.{1..30}.$part \
            --output $output_prefix.mbr.$part \
            --utility-function sentence-meteor &
    done

    wait

    cat $output_prefix.mbr.{1..16} > $output_prefix.mbr

    cat $output_prefix.mbr | cut -f2 > $output_prefix.mbr.text

fi
