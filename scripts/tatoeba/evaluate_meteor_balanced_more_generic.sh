#! /bin/bash

# calling script needs to set

# $scripts
# $METEOR
# $METEOR_PARAMS
# $untokenized_hyp
# $tokenized_ref
# $output

for unused in pseudo_loop; do

    if [[ -s $output ]]; then
        continue
    fi

    if [[ ! -f $untokenized_hyp.tok ]]; then
        cat $untokenized_hyp | \
            python $scripts/tokenize_v13a.py \
            > $untokenized_hyp.tok
    fi

    $METEOR \
        $untokenized_hyp.tok \
        $tokenized_ref \
        $METEOR_PARAMS -p "0.5 0.2 0.6 0.75" 2> /dev/null \
        > $output

    echo "$output"
    cat $output

done
