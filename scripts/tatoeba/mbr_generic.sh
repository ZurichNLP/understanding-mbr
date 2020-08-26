#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg
# $model_name

base=$1
src=$2
trg=$3
model_name=$4

scripts=$base/scripts

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mkdir -p $samples_sub_sub

source $base/venvs/sockeye3/bin/activate

# sampling translation

for corpus in dev test variations; do

    if [[ -s $samples_sub_sub/$corpus.mbr.text ]]; then
      echo "Mbr decodes exist: $samples_sub_sub/$corpus.mbr.text"

      num_lines_input=$(cat $samples_sub_sub/$corpus.1.trg | wc -l)
      num_lines_output=$(cat $samples_sub_sub/$corpus.mbr.text | wc -l)

      if [[ $num_lines_input == $num_lines_output ]]; then
          echo "output exists and number of lines are equal to input:"
          echo "$samples_sub_sub/$corpus.1.trg == $samples_sub_sub/$corpus.mbr.text"
          echo "$num_lines_input == $num_lines_output"
          echo "Skipping."
          continue
      else
          echo "$samples_sub_sub/$corpus.1.trg != $samples_sub_sub/$corpus.mbr.text"
          echo "$num_lines_input != $num_lines_output"
          echo "Repeating step."
      fi
    fi

    deactivate
    source $base/venvs/sockeye3-cpu/bin/activate

    # MBR

    python $scripts/mbr_decoding.py \
        --inputs $samples_sub_sub/$corpus.{1..30}.trg \
        --output $samples_sub_sub/$corpus.mbr \
        --utility-function sentence-meteor

    cat $samples_sub_sub/$corpus.mbr | cut -f2 > $samples_sub_sub/$corpus.mbr.text

done
