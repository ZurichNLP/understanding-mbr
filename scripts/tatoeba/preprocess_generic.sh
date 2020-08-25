#! /bin/bash

# calling process needs to set:
# base
# $src
# $trg

base=$1
src=$2
trg=$3

data=$base/data
venvs=$base/venvs
scripts=$base/scripts
shared_models=$base/shared_models

mkdir -p $shared_models

# subfolders

data_sub=$data/${src}-${trg}
shared_models_sub=$shared_models/${src}-${trg}

mkdir -p $shared_models_sub

source $venvs/sockeye3-cpu/bin/activate

MOSES=$base/tools/moses-scripts/scripts
TOKENIZER=$MOSES/tokenizer

SMALLEST_TRAINSIZE=10000
SMALL_TRAINSIZE=100000
MEDIUM_TRAINSIZE=500000
LARGE_TRAINSIZE=1000000
LARGEST_TRAINSIZE=10000000

# measure time

SECONDS=0

#################

echo "data_sub: $data_sub"

# prenormalization for train data

for corpus in train dev test; do
    for lang in src trg; do
        cat $data_sub/$corpus.$lang | \
        perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' | \
        perl -CS -pe 's/\&\s*\#\s*160\s*\;/ /g' \
        > $data_sub/$corpus.prenorm.$lang
    done
done

# langid filter

paste $data_sub/train.prenorm.src $data_sub/train.prenorm.trg | \
    python $scripts/bitext-match-lang.py -s ${src} -t ${trg} > $data_sub/train.langchecked.both

cut -f1 $data_sub/train.langchecked.both > $data_sub/train.langchecked.src
cut -f2 $data_sub/train.langchecked.both > $data_sub/train.langchecked.trg

# normalize data

for lang in src trg; do
    cat $data_sub/train.langchecked.$lang | \
    ${TOKENIZER}/replace-unicode-punctuation.perl | \
    ${TOKENIZER}/remove-non-printing-char.perl | \
    ${TOKENIZER}/deescape-special-chars.perl | \
    sed 's/  */ /g;s/^ *//g;s/ *$//g' > \
        $data_sub/train.normalized.$lang
done

for corpus in dev test; do
    for lang in src trg; do
        cat $data_sub/$corpus.prenorm.$lang | \
        ${TOKENIZER}/replace-unicode-punctuation.perl | \
        ${TOKENIZER}/remove-non-printing-char.perl | \
        ${TOKENIZER}/deescape-special-chars.perl | \
        sed 's/  */ /g;s/^ *//g;s/ *$//g' > \
            $data_sub/$corpus.normalized.$lang
    done
done

# determine $sentencepiece_vocab_size

num_lines=$(wc -l $data_sub/train.normalized.src)

if [ $num_lines -gt ${LARGEST_TRAINSIZE} ]; then
    sentencepiece_vocab_size=32000
elif [ $num_lines -gt ${LARGE_TRAINSIZE} ]; then
    sentencepiece_vocab_size=32000
elif [ $num_lines -gt ${MEDIUM_TRAINSIZE} ]; then
    sentencepiece_vocab_size=12000
elif [ $num_lines -gt ${SMALL_TRAINSIZE} ]; then
    sentencepiece_vocab_size=4000
elif [ $num_lines -gt ${SMALLEST_TRAINSIZE} ]; then
    sentencepiece_vocab_size=1000
else
    echo "Warning: training data size too small"
    exit 0
fi

# learn sentencepiece model on train (concatenate both languages)

for lang in src trg; do
    if [[ ! -f $shared_models_sub/$lang.sentencepiece.model ]]; then

      # determine character coverage

      num_characters=$(head -n 1000000 $data_sub/train.normalized.$lang | python $scripts/num_chars.py | wc -l)

      if [ $num_characters -gt 1000 ]; then
          character_coverage=0.9995
      else
          character_coverage=1.0
      fi

      python $scripts/tatoeba/train_sentencepiece.py \
        --model-prefix $shared_models_sub/$lang.sentencepiece \
        --input $data_sub/train.normalized.$lang \
        --vocab-size $sentencepiece_vocab_size \
        --character-coverage $character_coverage

    else
      echo "Sentencepiece model exists: $shared_models_sub/$lang.sentencepiece.model"
      echo "Skipping model training"
    fi
done

# create subnum variations of test set

python $scripts/create_variations.py \
    --input-src $data_sub/train.normalized.src \
    --input-trg $data_sub/train.normalized.trg \
    --output-src $data_sub/variations.normalized.src \
    --output-trg $data_sub/variations.normalized.trg \
    --output-variation-counts $data_sub/variations.count \
    --num-range 10

# apply SP model to train, test and dev + variations

for corpus in train dev test variations; do
    for lang in src trg; do
        cat $data_sub/$corpus.normalized.$lang | \
            python $scripts/tatoeba/apply_sentencepiece.py \
                --model $shared_models_sub/$lang.sentencepiece.model \
                    > $data_sub/$corpus.pieces.$lang
    done
done

# ratio etc filter

$MOSES/training/clean-corpus-n.perl $data_sub/train.pieces src trg $data_sub/train.clean 1 250

# sizes
echo "Sizes of all files:"

wc -l $data_sub/*
wc -l $shared_models_sub/*

echo "time taken:"
echo "$SECONDS seconds"
