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
logs_sub_sub=$logs_sub/$model_name

mkdir -p $logs_sub_sub

echo "##############################################"
echo "LANGPAIR: ${src}-${trg}" | tee -a $logs_sub_sub/MAIN
echo "MODEL NAME: $model_name" | tee -a $logs_sub_sub/MAIN
echo "ADDITIONAL TRAIN ARGS: $train_additional_args" | tee -a $logs_sub_sub/MAIN

# download corpus for language pair

id_download=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg $model_name
)

echo "  id_download: $id_download | $logs_sub_sub/slurm-$id_download.out" | tee -a $logs_sub_sub/MAIN

# preprocess: create subnum variations, normalize, SPM (depends on download)

id_preprocess=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic --dependency=afterok:$id_download \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg $model_name
)

echo "  id_preprocess: $id_preprocess | $logs_sub_sub/slurm-$id_preprocess.out" | tee -a $logs_sub_sub/MAIN

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic --dependency=afterok:$id_preprocess \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg $model_name
)

echo "  id_prepare: $id_prepare | $logs_sub_sub/slurm-$id_prepare.out"  | tee -a $logs_sub_sub/MAIN

# Sockeye train (depends on prepare)

id_train=$(
    $scripts/sbatch_bare.sh \
    --qos=vesta --time=72:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g --dependency=afterok:$id_prepare \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/train_generic.sh \
    $base $src $trg $model_name "$train_additional_args"
)

echo "  id_train: $id_train | $logs_sub_sub/slurm-$id_train.out"  | tee -a $logs_sub_sub/MAIN

# translate + sample test set (depends on train)

id_translate=$(
    $scripts/sbatch_bare.sh \
    --qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g --dependency=afterany:$id_train \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name
)

echo "  id_translate: $id_translate | $logs_sub_sub/slurm-$id_translate.out"  | tee -a $logs_sub_sub/MAIN

# MBR decode (depends on sampling)

id_mbr=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=32 --time=48:00:00 --mem=256G --partition=hpc --dependency=afterok:$id_translate \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/mbr_generic.sh \
    $base $src $trg $model_name
)

echo "  id_mbr: $id_mbr | $logs_sub_sub/slurm-$id_mbr.out"  | tee -a $logs_sub_sub/MAIN

# evaluate BLEU and variation range (depends on mbr)

id_evaluate=$(
    $scripts/sbatch_bare.sh \
    --cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic --dependency=afterok:$id_mbr \
    -o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN \
    $scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg $model_name
)

echo "  id_evaluate: $id_evaluate | $logs_sub_sub/slurm-$id_evaluate.out"  | tee -a $logs_sub_sub/MAIN
