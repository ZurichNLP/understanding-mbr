#! /bin/bash

# calling process needs to set:
# $base
# $src
# $trg
# $model_name
# $train_additional_args

SLURM_DEFAULT_FILE_PATTERN="slurm-%j.out"

module load volta cuda/10.2

scripts=$base/scripts
logs=$base/logs

logs_sub=$logs/${src}-${trg}

mkdir -p $logs_sub

echo "##############################################"
echo "LANGPAIR: ${src}-${trg}"
echo "MODEL NAME: $model_name"
echo "ADDITIONAL TRAIN ARGS: $train_additional_args"

# download corpus for language pair

id_download=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic \
    -o $logs_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg
)

echo "  id_download: $id_download"

# preprocess: create subnum variations, normalize, SPM (depends on download)

id_preprocess=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic --dependency=afterok:$id_download \
    -o $logs_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg
)

echo "  id_preprocess: $id_preprocess"

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic --dependency=afterok:$id_preprocess \
    -o $logs_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg
)

echo "  id_prepare: $id_prepare"

# Sockeye train (depends on prepare)

# TODO: time is set to 1 minute right now

id_train=$(
    $scripts/sbatch_bare.sh \
    --qos=vesta --time=00:01:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g --dependency=afterok:$id_prepare \
    -o $logs_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/train_generic.sh \
    $base $src $trg $model_name "$train_additional_args"
)

echo "  id_train: $id_train"

# translate + sample test set (depends on train)

id_translate=$(
    $scripts/sbatch_bare.sh \
    --qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g --dependency=afterany:$id_train \
    -o $logs_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name
)

echo "  id_translate: $id_translate"

exit

# evaluate BLEU and variation range (depends on translate)

echo "  id_evaluate:"

sbatch --cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic --dependency=afterok:$id_translate \
    -o $logs_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg
