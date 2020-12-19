#! /bin/bash

# calling script needs to set

# $base
# $nbest_input
# $source
# $reference
# $output_prefix

# overlap with source and reference

output=$output_prefix.nbest_overlap

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      continue
    fi

    python $base/scripts/measure_nbest_overlaps.py \
        --nbest-input $nbest_input \
        --source $source \
        --reference $reference \
        --output $output

done
