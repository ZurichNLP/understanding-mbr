#! /bin/bash

# calling script needs to set

# $scripts
# $hyp
# $ref
# $counts
# $average
# $output

for unused in pseudo_loop; do

    if [[ -s $average ]]; then
      continue
    fi

    python $scripts/eval_subnum.py \
    --ref $ref \
    --hyp $hyp \
    --num $counts \
    --average $average \
    > $output

    echo "$average"
    cat $average

done
