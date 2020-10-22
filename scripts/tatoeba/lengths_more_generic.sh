#! /bin/bash

# calling script needs to set

# $base
# $input
# $output

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      continue
    fi

    cat $input | $base/scripts/compute_lengths.py --output $output

done
