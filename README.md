# map-volatility

## Basic Setup

Clone this repo in the desired place, then:

### Install required software

Create a new virtualenv that uses Python 3. Please make sure to run this command outside of
any virtual Python environment:

    ./scripts/create_venv.sh

**Important**: Then activate the env by executing the `source` command that is output by the shell
script above.

Download and install required software:

    ./scripts/download.sh
    
## Tatoeba experiments

To run the entire pipeline (downloading data until evaluation of trained model) for a single language pair from Tatoeba, run

    ./scripts/tatoeba/run_sample.sh

The script will call `./scripts/tatoeba/run_tatoeba_generic.sh`, which will submit each individual step (such as translation, or model training) as a separate SLURM job. Depending on the nature of the task, the scripts submits to a different cluster, or asks for different resources. Steps within a pipeline depend on each other (SLURM sbatch `--afterok` dependency in most cases).

To run all required steps for a number of medium-resource language pairs, run

    ./scripts/tatoeba/run_mediums.sh
