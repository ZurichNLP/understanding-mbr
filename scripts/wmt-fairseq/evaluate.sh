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

variations=$base/variations
variations_sub=$variations/wmt

evaluations=$base/evaluations
evaluations_sub=$evaluations/wmt

mkdir -p $evaluations_sub

METEOR="java -Xmx2G -jar $base/tools/meteor/meteor-*.jar "
METEOR_PARAMS=" -l other -q"

# compute case-sensitive BLEU on detokenized data

for year in {13..20}; do

    if [[ -s $evaluations_sub/wmt$year.beam.bleu ]]; then
      continue
    fi

    # beam translations

    cat $translations_sub/wmt$year.$src-$trg.$trg.top | sacrebleu $data_sub/wmt$year.$src-$trg.$trg > $evaluations_sub/wmt$year.beam.bleu

    echo "$evaluations_sub/wmt$year.beam.bleu"
    cat $evaluations_sub/wmt$year.beam.bleu

    # single sample translation, e.g. samples/wmt/wmt20.de-en.en.text.1

    cat $samples_sub/wmt$year.$src-$trg.$trg.text.1 | sacrebleu $data_sub/wmt$year.$src-$trg.$trg > $evaluations_sub/wmt$year.single_sample.bleu

    echo "$evaluations_sub/wmt$year.single_sample.bleu"
    cat $evaluations_sub/wmt$year.single_sample.bleu

    # 30 samples, MBR decoding

    cat $samples_sub/wmt$year.$src-$trg.$trg.mbr.text | sacrebleu $data_sub/wmt$year.$src-$trg.$trg > $evaluations_sub/wmt$year.mbr.bleu

    echo "$evaluations_sub/wmt$year.mbr.bleu"
    cat $evaluations_sub/wmt$year.mbr.bleu

done

# compute METEOR with internal tokenization

for year in {13..20}; do

    if [[ -s evaluations_sub/wmt$year.beam.meteor ]]; then
      continue
    fi

    # tokenize reference once

    cat $data_sub/wmt$year.$src-$trg.$trg | \
        python $scripts/tokenize_v13a.py \
        > $data_sub/wmt$year.$src-$trg.$trg.tok

    # beam translations

    cat $translations_sub/wmt$year.$src-$trg.$trg.top | \
        python $scripts/tokenize_v13a.py \
        > $translations_sub/wmt$year.$src-$trg.$trg.top.tok

    $METEOR \
        $translations_sub/wmt$year.$src-$trg.$trg.top.tok \
        $data_sub/wmt$year.$src-$trg.$trg.tok \
        $METEOR_PARAMS | \
        tail -n 1 \
        > $evaluations_sub/wmt$year.beam.meteor

    echo "$evaluations_sub/wmt$year.beam.meteor"
    cat $evaluations_sub/wmt$year.beam.meteor

    # single sample translation

    cat $samples_sub/wmt$year.$src-$trg.$trg.text.1 | \
        python $scripts/tokenize_v13a.py \
        > $samples_sub/wmt$year.$src-$trg.$trg.text.1.tok

    $METEOR \
        $samples_sub/wmt$year.$src-$trg.$trg.text.1.tok \
        $data_sub/wmt$year.$src-$trg.$trg.tok \
        $METEOR_PARAMS | \
        tail -n 1 \
        > $evaluations_sub/wmt$year.single_sample.meteor

    echo "$evaluations_sub/wmt$year.single_sample.meteor"
    cat $evaluations_sub/wmt$year.single_sample.meteor

    # 30 samples, MBR decoding

    cat $samples_sub/wmt$year.$src-$trg.$trg.mbr.text | \
        python $scripts/tokenize_v13a.py \
        > $samples_sub/wmt$year.$src-$trg.$trg.mbr.text.tok

    $METEOR \
        $samples_sub/wmt$year.$src-$trg.$trg.mbr.text.tok \
        $data_sub/wmt$year.$src-$trg.$trg.tok \
        $METEOR_PARAMS | \
        tail -n 1 \
        > $evaluations_sub/wmt$year.mbr.meteor

    echo "$evaluations_sub/wmt$year.mbr.meteor"
    cat $evaluations_sub/wmt$year.mbr.meteor

done

# compute subnum variation ranges

# beam translations

python $scripts/eval_subnum.py \
    --ref $variations_sub/wmt.all.$trg \
    --hyp $translations_sub/variations.$trg.top \
    --num $variations_sub/wmt.all.count \
    --average $evaluations_sub/variations.beam.subnum.average \
    > $evaluations_sub/variations.beam.subnum

echo "$evaluations_sub/variations.beam.subnum.average"
cat $evaluations_sub/variations.beam.subnum.average

# MBR decoding

python $scripts/eval_subnum.py \
    --ref $variations_sub/wmt.all.$trg \
    --hyp $samples_sub/variations.mbr.text \
    --num $variations_sub/wmt.all.count \
    --average $evaluations_sub/variations.mbr.subnum.average \
    > $evaluations_sub/variations.mbr.subnum

echo "$evaluations_sub/variations.mbr.subnum.average"
cat $evaluations_sub/variations.mbr.subnum.average
