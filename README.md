# Understanding Minimum Bayes Risk Decoding

This repo provides code and documentation for the following paper:

Müller and Sennrich (2021): [Understanding the Properties of Minimum Bayes Risk Decoding in Neural Machine Translation](https://arxiv.org/pdf/2105.08504.pdf).


```
@inproceedings{muller2021understanding,
      title={Understanding the Properties of Minimum Bayes Risk Decoding in Neural Machine Translation}, 
      author = {M{\"u}ller, Mathias  and
      Sennrich, Rico},
      year={2021},
      eprint={2105.08504},
      booktitle = "Proceedings of the Joint Conference of the 59th Annual Meeting of the Association for Computational Linguistics and the 11th International Joint Conference on Natural Language Processing (ACL-IJCNLP 2021)"
}
```

## Basic Setup

Clone this repo in the desired place:

    git clone https://github.com/ZurichNLP/understanding-mbr
    cd understanding-mbr

then proceed to install software before running any experiments.

### Install required software

**Create a virtual environment**

Create a new virtualenv that uses Python 3. Please make sure to run this command outside of
any virtual Python environment:

    ./scripts/create_venv.sh

All other subsequent scripts will automatically activate the correct envs by executing `source` commands.

**Note on Python versions**

The exact Python version we used for the experiments is `3.6.12`. `scripts/create_venv.sh` calls `pyenv` to set this specific version, assuming it was installed previously with `pyenv`. If you don't have `pyenv` on your system you can either a) install it (which can be complicated) or b) use the default Python 3 available on your system, which will probably not lead to an error. If b) then you need to remove calls to `pyenv` in `scripts/create_venv.sh`.

The script above also assumes that `virtualenv` is installed on the system.

**Install software**

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

**IMPORTANT**: if
- you do not work on a cluster that uses SLURM for job management,
- your cluster layout, resource naming etc. is different
  
you absolutely need to modify or replace the generic script `scripts/tatoeba/run_tatoeba_generic.sh` before running anything. If you do
not use SLURM at all, it might be possible to just replace calls to `scripts/tatoeba/run_tatoeba_generic.sh` with
`scripts/tatoeba/run_tatoeba_generic_no_slurm.sh`.

`scripts/tatoeba/run_tatoeba_generic_no_slurm.sh` is a script we provide for convenience, but have not tested it ourselves.
We cannot guarantee that it runs without error.

### Dry run

Before you run actual experiments, it can be useful to perform a dry run. Dry runs attempt to run all commands, create all files etc. but are finished
within minutes and use CPU only. Dry runs help to catch some bugs (such as file permissions) early.

Before calling a dry run script, make sure to change the `base` variable to an actual folder on your system, the one that contains your clone of this repo.

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
This means that if a job X fails, subsequent jobs that depend on X will never start. If you attempt to re-run completed steps
they exit immediately -- so you can always re-run an entire pipeline if any step fails.

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

This is possible only because we have hosted the results of our experiments on our servers and Colab can retrieve files
from there.

## Browse MBR samples

We also provide examples for pools of MBR samples for your perusal, as HTML files that can be viewed
in any browser. The example HTML files are created by running the following
script:

    ./scripts/tatoeba/local_html.sh

and are available at the following URLs (Markdown does not support clickable links, sorry!):

### Domain robustness

<table>
    <thead>
        <th>language pair</th>
        <th>domain test set</th>
        <th>link</th>
    </thead>
    <tbody>
        <tr>
            <td>DEU-ENG</td>
            <td>it</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/deu-eng.domain_robustness.it.html</a></td>
        </tr>
<tr>
            <td>DEU-ENG</td>
            <td>koran</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/deu-eng.domain_robustness.koran.html</a></td>
        </tr>
<tr>
            <td>DEU-ENG</td>
            <td>law</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/deu-eng.domain_robustness.law.html</a></td>
        </tr>
<tr>
            <td>DEU-ENG</td>
            <td>medical</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/deu-eng.domain_robustness.medical.html</a></td>
        </tr>
<tr>
            <td>DEU-ENG</td>
            <td>subtitles</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/deu-eng.domain_robustness.subtitles.html</a></td>
        </tr>
    </tbody>
</table>

### Copy noise in training data

<table>
    <thead>
        <th>language pair</th>
        <th>amount of copy noise</th>
        <th>link</th>
    </thead>
    <tbody>
        <tr>
            <td>ARA-DEU</td>
            <td>0.001</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.001.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.005</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.005.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.01</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.01.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.05</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.05.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.075</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.075.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.1</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.1.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.25</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.25.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ARA-DEU</td>
            <td>0.5</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/ara-deu.copy_noise.0.5.slice-test.html</a></td>
        </tr>
    </tbody>
</table>

<table>
    <thead>
        <th>language pair</th>
        <th>amount of copy noise</th>
        <th>link</th>
    </thead>
    <tbody>
        <tr>
            <td>ENG-MAR</td>
            <td>0.001</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.001.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.005</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.005.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.01</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.01.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.05</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.05.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.075</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.075.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.1</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.1.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.25</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.25.slice-test.html</a></td>
        </tr>
        <tr>
            <td>ENG-MAR</td>
            <td>0.5</td>
            <td><a>https://files.ifi.uzh.ch/cl/archiv/2020/clcontra/eng-mar.copy_noise.0.5.slice-test.html</a></td>
        </tr>
    </tbody>
</table>
