#! /bin/bash

# calling process needs to set
# $input
# $output
# $parts_prefix

if [[ -s $output.text ]]; then
  echo "Mbr decodes exist: $output.text"

  num_lines_input=$(cat $input | wc -l)
  num_lines_output=$(cat $output.text | wc -l)

  if [[ $num_lines_input == $num_lines_output ]]; then
      echo "output exists and number of lines are equal to input:"
      echo "$input == $output.text"
      echo "$num_lines_input == $num_lines_output"
      echo "Skipping."
  else
      echo "$input != $output.text"
      echo "$num_lines_input != $num_lines_output"
      echo "Repeating step."

      # parallel decoding, assuming 8 physical cores

      for part in {1..8}; do

          python $scripts/mbr_decoding.py \
              --input $input.$part \
              --output $parts_prefix.$part \
              --utility-function sentence-meteor \
              --num-samples $num_samples &
      done

      wait

      # concatenate parts

      cat $parts_prefix.{1..8} > $output

      # remove MBR scores, leaving only the text

      cat $output | cut -f2 > $output.text
  fi
fi
