#! /bin/bash

# calling script needs to set

# $hyp
# $ref
# $output
# $chrf_beta

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
      continue
    fi

    cat $hyp | sacrebleu $ref --metrics chrf -w 3 --chrf-beta $chrf_beta > $output

    echo "$output"
    cat $output

done
