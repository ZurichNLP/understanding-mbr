# Understanding Minimum Bayes Risk Decoding

This repo provides code and documentation for the following paper:

Müller and Sennrich (2021): Understanding the Properties of Minimum Bayes Risk Decoding in Neural Machine Translation.

## Basic Setup

Clone this repo in the desired place:

    git clone https://github.com/ZurichNLP/understanding-mbr
    cd understanding-mbr

then proceed to install software before running any experiments.

### Install required software

Create a new virtualenv that uses Python 3. Please make sure to run this command outside of
any virtual Python environment:

    ./scripts/create_venv.sh

**Important**: Then activate the env by executing the `source` command that is output by the shell
script above.

Download and install required software:

    ./scripts/download.sh

The download script makes several important assumptions, such as: your OS is Linux, you have CUDA 10.2 installed, you have access to a GPU for training
and translation, your folder for temp files is `/var/tmp`. Edit the script before running it to fit to your needs.

## Running experiments in general

### Definition of "run"

We define a "run" as one complete experiment, in the sense that a run executes a pipeline of steps. Every run is completely self-contained:
it does everything from downloading the data until  evaluation of a trained model.

The series of steps executed in a run is defined in

    scripts/tatoeba/run_tatoeba_generic.sh

This script is generic and will never be called on its own (many variables would be undefined), but all our scripts eventually call
this script.

### SLURM jobs

Individual steps in runs are submitted to a SLURM system. The generic run script:

    scripts/tatoeba/run_tatoeba_generic.sh

will submit each individual step (such as translation, or model training) as a separate SLURM job. Depending on the nature of the task,
the scripts submits to a different cluster, or asks for different resources.

IMPORTANT: if
- you do not work on a cluster that uses SLURM for job management,
- your cluster layout, resource naming etc. is different
  
you absolutely need to modify the generic script `scripts/tatoeba/run_tatoeba_generic.sh` before running anything.

### Dry run

Before you run actual experiments, it can be useful to perform a dry run. Dry runs attempt to run all commands, create all files etc. but are finished
within minutes and use CPU only. Dry runs help to catch some bugs (such as file permissions) early.

To dry-run a baseline system for the language pair DAN-EPO, run:

    ./scripts/tatoeba/dry_run_baseline.sh

### Single (non-dry!) example run

To run the entire pipeline (downloading data until evaluation of trained model) for a single language pair from Tatoeba, run

    ./scripts/tatoeba/run_baseline.sh

This will train a model for the language pair DAN-EPO, but also execute all steps before and after model training.

### Start a certain group of runs

It is possible to submit several runs at the same time, using the same shell script.
For instance, to run all required steps for a number of medium-resource language pairs, run

    ./scripts/tatoeba/run_mediums.sh

### Recovering partial runs

Steps within a run pipeline depend on each other (SLURM sbatch `--afterok` dependency in most cases).
This means that if a job X fails, subsequent jobs that depend on X will never start. If steps are completed,
the exit immediately -- so you can always re-run an entire pipeline if any step fails.

## Reproducing the results presented in our paper in particular

### Training and evaluating the models

To create all models and statistics necessary to compare MBR with different utility functions:

    scripts/tatoeba/run_compare_risk_functions.sh

To reproduce experiments on domain robustness:

    scripts/tatoeba/run_robustness_data.sh

To reproduce experiments on copy noise in the training data:

    scripts/tatoeba/run_copy_noise.sh

### Creating visualizations and result tables

To reproduce exactly the tables and figures we show in the paper, use our Google Colab here:

https://colab.research.google.com/drive/1GYZvxRB1aebOThGllgb0teY8A4suH5j-?usp=sharing

This is possible only after running the experiments themselves as described in earlier sections.
