#! /bin/bash

# calling script needs to set

# $base
# $input
# $output

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      continue
    fi

    cat $input | python $base/scripts/token_counts.py --output $output

done
