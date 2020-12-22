#! /bin/bash

# calling script needs to set

# $base
# $overlaps_source
# $overlaps_reference
# $threshold_copy
# $threshold_hallucination
# $output

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      continue
    fi

    python $base/scripts/extract_from_overlaps.py \
        --overlaps-source $overlaps_source \
        --overlaps-reference $overlaps_reference \
        --output $output \
        --threshold-copy $threshold_copy \
        --threshold-hallucination $threshold_hallucination

done
