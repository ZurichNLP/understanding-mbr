#! /bin/bash

# calling script needs to set

# $base
# $src
# $trg
# $model_name

source $base/venvs/sockeye3-cpu/bin/activate

scripts=$base/scripts

data=$base/data
data_sub=$data/${src}-${trg}
data_sub_sub=$data_sub/$model_name

translations=$base/translations
translations_sub=$translations/${src}-${trg}
translations_sub_sub=$translations_sub/$model_name

samples=$base/samples
samples_sub=$samples/${src}-${trg}
samples_sub_sub=$samples_sub/$model_name

mbr=$base/mbr
mbr_sub=$mbr/${src}-${trg}
mbr_sub_sub=$mbr_sub/$model_name

evaluations=$base/evaluations
evaluations_sub=$evaluations/${src}-${trg}
evaluations_sub_sub=$evaluations_sub/$model_name

mkdir -p $evaluations_sub_sub

METEOR="java -Xmx2G -jar $base/tools/meteor/meteor-*.jar "
METEOR_PARAMS=" -l other -q"

# compute METEOR with internal tokenization

for corpus in dev test; do

    if [[ -s $evaluations_sub_sub/$corpus.beam.meteor ]]; then
      continue
    fi

    # tokenize reference once

    cat $data_sub_sub/$corpus.trg | \
        python $scripts/tokenize_v13a.py \
        > $data_sub_sub/$corpus.trg.tok

    # beam translations

    cat $translations_sub_sub/$corpus.trg | \
        python $scripts/tokenize_v13a.py \
        > $translations_sub_sub/$corpus.trg.tok

    $METEOR \
        $translations_sub_sub/$corpus.trg.tok \
        $data_sub_sub/$corpus.trg.tok \
        $METEOR_PARAMS 2> /dev/null \
        > $evaluations_sub_sub/$corpus.beam.meteor

    echo "$evaluations_sub_sub/$corpus.beam.meteor"
    cat $evaluations_sub_sub/$corpus.beam.meteor

    # single sample translation

    cat $samples_sub_sub/$corpus.1.trg | \
        python $scripts/tokenize_v13a.py \
        > $samples_sub_sub/$corpus.1.trg.tok

    $METEOR \
        $samples_sub_sub/$corpus.1.trg.tok \
        $data_sub_sub/$corpus.trg.tok \
        $METEOR_PARAMS 2> /dev/null \
        > $evaluations_sub_sub/$corpus.single_sample.meteor

    echo "$evaluations_sub_sub/$corpus.single_sample.meteor"
    cat $evaluations_sub_sub/$corpus.single_sample.meteor

    # 30 samples, MBR decoding

    cat $samples_sub_sub/$corpus.mbr.text | \
        python $scripts/tokenize_v13a.py \
        > $samples_sub_sub/$corpus.mbr.text.tok

    $METEOR \
        $samples_sub_sub/$corpus.mbr.text.tok \
        $data_sub_sub/$corpus.trg.tok \
        $METEOR_PARAMS 2> /dev/null \
        > $evaluations_sub_sub/$corpus.mbr.meteor

    echo "$evaluations_sub_sub/$corpus.mbr.meteor"
    cat $evaluations_sub_sub/$corpus.mbr.meteor

done
