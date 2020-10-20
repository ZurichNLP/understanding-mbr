#! /bin/bash

# calling process needs to set:
# $base
# $src
# $trg
# $model_name
#
# optional:
# $train_additional_args
# $preprocess_copy_noise_probability
# $dry_run
# $utility_functions
# $mbr_execute_on_generic

# if variables are undefined, set to avoid confusion

if [ -z "$dry_run" ]; then
    dry_run="false"
fi

if [ -z "$train_additional_args" ]; then
    train_additional_args=""
fi

if [ -z "$utility_functions" ]; then
    utility_functions="sentence-chrf-symmetric"
fi

if [ -z "$preprocess_copy_noise_probability" ]; then
    preprocess_copy_noise_probability="0.0"
fi

if [ -z "$mbr_execute_on_generic" ]; then
    mbr_execute_on_generic="false"
fi

# SLURM job args

DRY_RUN_SLURM_ARGS="--cpus-per-task=2 --time=01:00:00 --mem=8G --partition=generic"

SLURM_ARGS_GENERIC="--cpus-per-task=2 --time=24:00:00 --mem=8G --partition=generic"
SLURM_ARGS_GENERIC_LARGE="--cpus-per-task=8 --time=24:00:00 --mem=32G --partition=generic"
SLURM_ARGS_HPC="--cpus-per-task=32 --time=72:00:00 --mem=256G --partition=hpc"
SLURM_ARGS_VOLTA_TRAIN="--qos=vesta --time=72:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"
SLURM_ARGS_VOLTA_TRANSLATE="--qos=vesta --time=12:00:00 --gres gpu:Tesla-V100-32GB:1 --cpus-per-task 1 --mem 16g"

if [[ $mbr_execute_on_generic == "true" ]]; then
  SLURM_ARGS_HPC=$SLURM_ARGS_GENERIC_LARGE
fi

# if dry run, then all args use generic instances

if [[ $dry_run == "true" ]]; then
  SLURM_ARGS_GENERIC=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_HPC=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRAIN=$DRY_RUN_SLURM_ARGS
  SLURM_ARGS_VOLTA_TRANSLATE=$DRY_RUN_SLURM_ARGS
fi

module load volta cuda/10.2

scripts=$base/scripts
logs=$base/logs

logs_sub=$logs/${src}-${trg}
logs_sub_sub=$logs_sub/$model_name

SLURM_DEFAULT_FILE_PATTERN="slurm-%j.out"
SLURM_LOG_ARGS="-o $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN -e $logs_sub_sub/$SLURM_DEFAULT_FILE_PATTERN"

mkdir -p $logs_sub_sub

echo "##############################################" | tee -a $logs_sub_sub/MAIN
date | tee -a $logs_sub_sub/MAIN
echo "##############################################" | tee -a $logs_sub_sub/MAIN
echo "LANGPAIR: ${src}-${trg}" | tee -a $logs_sub_sub/MAIN
echo "MODEL NAME: $model_name" | tee -a $logs_sub_sub/MAIN
echo "PREPROCESS COPY NOISE PROB: $preprocess_copy_noise_probability" | tee -a $logs_sub_sub/MAIN
echo "ADDITIONAL TRAIN ARGS: $train_additional_args" | tee -a $logs_sub_sub/MAIN
echo "UTILITY FUNCTIONS: $utility_functions" | tee -a $logs_sub_sub/MAIN
echo "DRY RUN: $dry_run" | tee -a $logs_sub_sub/MAIN

# download corpus for language pair

id_download=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/download_corpus_generic.sh \
    $base $src $trg $model_name
)

echo "  id_download: $id_download | $logs_sub_sub/slurm-$id_download.out" | tee -a $logs_sub_sub/MAIN

# preprocess: create subnum variations, normalize, SPM, maybe insert copy noise (depends on download)

id_preprocess=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_download \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/preprocess_generic.sh \
    $base $src $trg $model_name $preprocess_copy_noise_probability $dry_run
)

echo "  id_preprocess: $id_preprocess | $logs_sub_sub/slurm-$id_preprocess.out" | tee -a $logs_sub_sub/MAIN

# Sockeye prepare (depends on preprocess)

id_prepare=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_preprocess \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/prepare_generic.sh \
    $base $src $trg $model_name
)

echo "  id_prepare: $id_prepare | $logs_sub_sub/slurm-$id_prepare.out"  | tee -a $logs_sub_sub/MAIN

# Sockeye train (depends on prepare)

id_train=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRAIN \
    --dependency=afterok:$id_prepare \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/train_generic.sh \
    $base $src $trg $model_name "$train_additional_args" $dry_run
)

echo "  id_train: $id_train | $logs_sub_sub/slurm-$id_train.out"  | tee -a $logs_sub_sub/MAIN

# translate + sample test set (depends on train)

id_translate=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_VOLTA_TRANSLATE \
    --dependency=afterany:$id_train \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/translate_generic.sh \
    $base $src $trg $model_name $dry_run
)

echo "  id_translate: $id_translate | $logs_sub_sub/slurm-$id_translate.out"  | tee -a $logs_sub_sub/MAIN

# MBR decode (depends on sampling)

id_mbr=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_HPC \
    --dependency=afterok:$id_translate \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/mbr_generic.sh \
    $base $src $trg $model_name $dry_run $utility_functions $mbr_execute_on_generic
)

echo "  id_mbr: $id_mbr | $logs_sub_sub/slurm-$id_mbr.out"  | tee -a $logs_sub_sub/MAIN

# evaluate BLEU and variation range (depends on mbr)

id_evaluate=$(
    $scripts/sbatch_bare.sh \
    $SLURM_ARGS_GENERIC \
    --dependency=afterok:$id_mbr \
    $SLURM_LOG_ARGS \
    $scripts/tatoeba/evaluate_generic.sh \
    $base $src $trg $model_name $utility_functions
)

echo "  id_evaluate: $id_evaluate | $logs_sub_sub/slurm-$id_evaluate.out"  | tee -a $logs_sub_sub/MAIN
