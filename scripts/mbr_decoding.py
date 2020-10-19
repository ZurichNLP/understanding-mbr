#! /usr/bin/python3

import sacrebleu
import argparse
import logging
import json

import numpy as np

from typing import Callable, Tuple, List
from eval_meteor import MeteorScorer


meteor_scorer = MeteorScorer()


UTILITY_SENTENCE_BLEU = "sentence-bleu"
UTILITY_SENTENCE_METEOR = "sentence-meteor"
UTILITY_SENTENCE_TER = "sentence-ter"
UTILITY_SENTENCE_CHRF = "sentence-chrf"

UTILITY_SENTENCE_BLEU_SYMMETRIC = "sentence-bleu-symmetric"
UTILITY_SENTENCE_METEOR_SYMMETRIC = "sentence-meteor-symmetric"
UTILITY_SENTENCE_TER_SYMMETRIC = "sentence-ter-symmetric"
UTILITY_SENTENCE_CHRF_SYMMETRIC = "sentence-chrf-symmetric"

UTILITY_FUNCTIONS = [UTILITY_SENTENCE_BLEU,
                     UTILITY_SENTENCE_METEOR,
                     UTILITY_SENTENCE_TER,
                     UTILITY_SENTENCE_CHRF,
                     UTILITY_SENTENCE_BLEU_SYMMETRIC,
                     UTILITY_SENTENCE_METEOR_SYMMETRIC,
                     UTILITY_SENTENCE_TER_SYMMETRIC,
                     UTILITY_SENTENCE_CHRF_SYMMETRIC]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=str, help="Samples of translations. Expect one JSON per line with nbest list.")
    parser.add_argument("--output", type=str, help="File to write best samples.", required=True)
    parser.add_argument("--utility-function", type=str, help="Utility function to compare average risk of samples",
                        required=True, choices=UTILITY_FUNCTIONS)
    parser.add_argument("--num-samples", type=int, help="How many samples to use for MBR (default: all translations "
                                                        "found in --input).",
                        required=False, default=-1)
    parser.add_argument("--sample-start-index", type=int,
                        help="From each nbest list take a slice of --num-samples samples, but start at this index "
                             "(default: 0).",
                        required=False, default=0)
    parser.add_argument("--dry-run", action="store_true", help="Do not compute actual scores, mockup for dry runs.",
                        required=False, default=False)

    args = parser.parse_args()

    return args


def wrap_symmetric(utility_function: Callable,
                   hyp: str,
                   ref: str) -> np.ndarray:
    """

    :param utility_function:
    :param hyp:
    :param ref:
    :return:
    """
    forward = utility_function(hyp, ref)
    backward = utility_function(ref, hyp)

    return np.mean([forward, backward])


def compute_meteor(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    return meteor_scorer.score(ref, hyp)


def compute_ter(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_ter(hyp, ref).score


def compute_bleu(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_bleu(hyp, ref).score


def compute_chrf(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_chrf(hyp, ref).score


UTILITY_LOOKUP = {UTILITY_SENTENCE_BLEU: compute_bleu,
                  UTILITY_SENTENCE_METEOR: compute_meteor,
                  UTILITY_SENTENCE_TER: compute_ter,
                  UTILITY_SENTENCE_CHRF: compute_chrf}


def get_maximum_utility_sample(samples: List[str],
                               utility_function: Callable,
                               symmetric: bool = False) -> Tuple[str, float]:
    """

    :param samples: Sampled target translations for one single source input sentence
    :param utility_function: Function to compare one sample to all other samples
    :param symmetric: Compute utility function in both directions hyp<->ref
    :return:
    """

    average_utilities = []

    for sample in samples:

        utilities = []

        for pseudo_reference in samples:
            if symmetric:
                utility = wrap_symmetric(utility_function, sample, pseudo_reference)
            else:
                utility = utility_function(sample, pseudo_reference)
            utilities.append(utility)

        if len(utilities) == 0:
            average_utility = 0.0
        else:
            average_utility = np.mean(utilities)

        average_utilities.append(average_utility)

    maximum_utility_index = int(np.argmax(average_utilities))

    return samples[maximum_utility_index], np.max(average_utilities)


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handle = open(args.input, "r")
    output_handle = open(args.output, "w")

    if "symmetric" in args.utility_function:
        symmetric_utility = True
        utility_function = args.utility_function.replace("-symmetric", "")
    else:
        symmetric_utility = False
        utility_function = args.utility_function

    utility_function = UTILITY_LOOKUP[utility_function]

    for line in input_handle:
        jobj = json.loads(line)
        samples = jobj["translations"]

        if args.num_samples > -1:
            samples = samples[args.sample_start_index:args.num_samples]
            assert len(samples) >= args.num_samples, "Slicing with --sample-start-index selected " \
                                                     "fewer translations than --num-samples!"

        # remove samples if they are the empty string or whitespace-only
        samples = [sample for sample in samples if sample.strip() != ""]

        if args.dry_run:
            output, utility = samples[0], 0.0
        else:
            output, utility = get_maximum_utility_sample(samples=samples,
                                                         utility_function=utility_function,
                                                         symmetric=symmetric_utility)

        output = output.strip()
        output_handle.write("%f\t%s\n" % (utility, output))


if __name__ == "__main__":
    main()
