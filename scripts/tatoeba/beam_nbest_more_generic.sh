#! /bin/bash

# calling script needs to set

# $base
# $input
# $output_pieces
# $output
# $length_penalty_alpha
# $models_sub_sub
# $dry_run
# $num_samples
# $nbest_batch_size

if [[ $dry_run == "true" ]]; then
    batch_size=2
    dry_run_additional_args="--use-cpu"
else
    batch_size=$nbest_batch_size
    dry_run_additional_args=""
fi

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      echo "Translations exist: $output"

      num_lines_input=$(cat $input | wc -l)
      num_lines_output=$(cat $output | wc -l)

      if [[ $num_lines_input == $num_lines_output ]]; then
          echo "output exists and number of lines are equal to input:"
          echo "$input == $output"
          echo "$num_lines_input == $num_lines_output"
          echo "Skipping."
          continue
      else
          echo "$input != $output"
          echo "$num_lines_input != $num_lines_output"
          echo "Repeating step."
      fi
    fi

    # produce nbest list of size $num_samples

    OMP_NUM_THREADS=1 python -m sockeye.translate \
            -i $input \
            -o $output_pieces \
            -m $models_sub_sub \
            --beam-size $num_samples \
            --nbest-size $num_samples \
            --length-penalty-alpha $length_penalty_alpha \
            --device-ids 0 \
            --batch-size $batch_size \
            --disable-device-locking $dry_run_additional_args

    # undo pieces in nbest JSON structures

    python $base/scripts/remove_pieces_from_nbest.py \
        --input $output_pieces > \
        $output

done
