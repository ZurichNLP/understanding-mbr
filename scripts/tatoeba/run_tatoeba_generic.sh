#! /bin/bash

# calling process needs to set:
# $base
# $src
# $trg

module load volta cuda/10.2

scripts=$base/scripts

# download corpus for language pair

id_download=$(
    $scripts/sbatch-bare.sh \
    sbatch --cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic \
    $scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg
)

# preprocess: create subnum variations, normalize, SPM (depends on download)

id_preprocess=$(
    $scripts/sbatch-bare.sh \
    sbatch --cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic --dependency=afterany:$id_download \
    $scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg
)

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/sbatch-bare.sh \
    sbatch --cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic --dependency=afterany:$id_preprocess \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg
)

# Sockeye train (depends on prepare)

model_name=baseline
additional_args=""

id_train=$(
    $scripts/sbatch-bare.sh \
    sbatch --qos=vesta --time=72:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g --dependency=afterany:$id_prepare \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg $model_name "$additional_args"
)

# translate + sample test set (depends on train)

model_name=baseline

id_translate=$(
    $scripts/sbatch-bare.sh \
    sbatch --qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g --dependency=afterany:$id_train \
    $scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name
)

# evaluate BLEU and variation range (depends on translate)

sbatch --cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic --dependency=afterany:$id_translate \
    $scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg

# TODO: generate summary?
