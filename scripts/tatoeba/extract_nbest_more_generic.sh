#! /bin/bash

# calling script needs to set

# $base
# $nbest_input
# $nbest_output
# $threshold_copy
# $threshold_hallucination
# $output
# $overlap_function_reference

for unused in pseudo_loop; do

    if [[ -s $nbest_output ]]; then
      continue
    fi

    python $base/scripts/extract_from_nbest_overlaps.py \
        --nbest-input $nbest_input \
        --nbest-output $nbest_output \
        --threshold-copy $threshold_copy \
        --threshold-hallucination $threshold_hallucination \
        --overlap-function-reference $overlap_function_reference

done
