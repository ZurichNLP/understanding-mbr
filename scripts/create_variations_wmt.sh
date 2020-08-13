#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/..

data=$base/data
variations=$base/variations

mkdir -p $variations

variations_sub=$variations/wmt

mkdir -p $variations_sub

src=de
trg=en

for year in {13..20}; do

    python $scripts/create_variations.py \
        --input-src $data/wmt$year.$src-$trg.$src \
        --input-trg $data/wmt$year.$src-$trg.$trg \
        --output-src $variations_sub/wmt$year.$src-$trg.$src \
        --output-trg $variations_sub/wmt$year.$src-$trg.$trg \
        --output-variation-counts $variations_sub/wmt$year.$src-$trg.count \
        --num-range 10
done

# combine into single files

for lang in $src $trg; do

  rm -f $variations_sub/all.$lang

  cat $variations_sub/*.$lang > $variations_sub/all.$lang

done

rm -f $variations_sub/all.count

cat $variations_sub/*.count > $variations_sub/all.count
