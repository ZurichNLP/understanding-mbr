#! /bin/bash

scripts=`dirname "$0"`
base=$scripts/../..

src=de
trg=en

source $base/venv/fairseq3/bin/activate

data=$base/data
data_sub=$data/wmt

translations=$base/translations
translations_sub=$translations/wmt

samples=$base/samples
samples_sub=$samples/wmt

evaluations=$base/evaluations
evaluations_sub=$evaluations/wmt

mkdir -p $evaluations_sub

METEOR="java -Xmx2G -jar $base/tools/meteor/meteor-*.jar"
METEOR_PARAMS="-l other -q"

# compute METEOR with internal tokenization

for year in 13; do

    if [[ -s evaluations_sub/wmt$year.beam.meteor ]]; then
      continue
    fi

    # tokenize reference once

    cat $data_sub/wmt$year.$src-$trg.$trg | \
        python $base/scripts/tokenize_v13a.py \
        > $data_sub/wmt$year.$src-$trg.$trg.tok

    # beam translations

    cat $translations_sub/wmt$year.$src-$trg.$trg.top | \
        python $base/scripts/tokenize_v13a.py \
        > $translations_sub/wmt$year.$src-$trg.$trg.top.tok

    $METEOR \
        $translations_sub/wmt$year.$src-$trg.$trg.top.tok \
        $data_sub/wmt$year.$src-$trg.$trg.tok \
        $METEOR_PARAMS 2> /dev/null \
        > $evaluations_sub/wmt$year.beam.meteor

    echo "$evaluations_sub/wmt$year.beam.meteor"
    cat $evaluations_sub/wmt$year.beam.meteor

done