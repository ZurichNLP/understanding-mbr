#! /bin/bash

# calling process needs to set
# $input
# $output
# $parts_prefix
# $num_samples
# $utility_function
# $dry_run
# $ref
# $oracle

if [[ $oracle == "true" ]]; then
    ref_argument="--references $ref"
else
    ref_argument=""
fi

# pseudo loop to check if file exists

for unused in useless_loop_var; do

    if [[ -s $output.text ]]; then
      echo "Mbr decodes exist: $output.text"

      num_lines_input=$(cat $input | wc -l)
      num_lines_output=$(cat $output.text | wc -l)

      if [[ $num_lines_input == $num_lines_output ]]; then
          echo "output exists and number of lines are equal to input:"
          echo "$input == $output.text"
          echo "$num_lines_input == $num_lines_output"
          echo "Skipping."
          continue
      else
          echo "$input != $output.text"
          echo "$num_lines_input != $num_lines_output"
          echo "Repeating step."
      fi
    fi

    # ugly, but curly brace expressions do not allow variable expansion

    if [[ $dry_run == "true" ]]; then

        # parallel decoding, assuming 2 physical cores

        for part in {1..2}; do

            python $scripts/mbr_decoding.py \
                --input $input.$part \
                --output $parts_prefix.$part \
                --utility-function $utility_function \
                --num-samples $num_samples \
                --dry-run $ref_argument &
        done

        wait

        # concatenate parts

        cat $parts_prefix.{1..2} > $output

    else
        # parallel decoding, assuming 32 physical cores

        for part in {1..32}; do

            python $scripts/mbr_decoding.py \
                --input $input.$part \
                --output $parts_prefix.$part \
                --utility-function $utility_function \
                --num-samples $num_samples $ref_argument &
        done

        wait

        # concatenate parts

        cat $parts_prefix.{1..32} > $output
    fi

    # extract the text of the best sample

    cat $output | python $scripts/extract_best_sample_from_mbr.py > $output.text

done
