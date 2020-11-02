#! /bin/bash

# calling script needs to set

# $hyp
# $ref
# $output

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      continue
    fi

    cat $hyp | sacrebleu $ref --metrics chrf -w 2 > $output

    echo "$output"
    cat $output

done
