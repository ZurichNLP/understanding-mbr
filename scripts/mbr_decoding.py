#! /usr/bin/python3

import argparse
import logging
import json
import itertools

import numpy as np

from scipy import stats
from typing import Tuple, List, Union, Optional
from sacrebleu import TER, DEFAULT_TOKENIZER

# local dependencies

import eval_meteor
import cached_metrics


UTILITY_SENTENCE_BLEU = "sentence-bleu"
UTILITY_SENTENCE_BLEU_FLOOR = "sentence-bleu-floor"
UTILITY_SENTENCE_BLEU_ADD_K = "sentence-bleu-add-k"
UTILITY_SENTENCE_BLEU_EXP = "sentence-bleu-exp"
UTILITY_SENTENCE_METEOR = "sentence-meteor"
UTILITY_SENTENCE_METEOR_BALANCED = "sentence-meteor-balanced"
UTILITY_SENTENCE_TER = "sentence-ter"
UTILITY_SENTENCE_CHRF = "sentence-chrf"
UTILITY_SENTENCE_CHRF_BALANCED = "sentence-chrf-balanced"

UTILITY_SENTENCE_BLEU_SYMMETRIC = "sentence-bleu-symmetric"
UTILITY_SENTENCE_BLEU_FLOOR_SYMMETRIC = "sentence-bleu-floor-symmetric"
UTILITY_SENTENCE_BLEU_ADD_K_SYMMETRIC = "sentence-bleu-add-k-symmetric"
UTILITY_SENTENCE_BLEU_EXP_SYMMETRIC = "sentence-bleu-exp-symmetric"
UTILITY_SENTENCE_METEOR_SYMMETRIC = "sentence-meteor-symmetric"
UTILITY_SENTENCE_TER_SYMMETRIC = "sentence-ter-symmetric"
UTILITY_SENTENCE_CHRF_SYMMETRIC = "sentence-chrf-symmetric"

UTILITY_FUNCTIONS = [UTILITY_SENTENCE_BLEU,
                     UTILITY_SENTENCE_BLEU_FLOOR,
                     UTILITY_SENTENCE_BLEU_ADD_K,
                     UTILITY_SENTENCE_BLEU_EXP,
                     UTILITY_SENTENCE_METEOR,
                     UTILITY_SENTENCE_METEOR_BALANCED,
                     UTILITY_SENTENCE_TER,
                     UTILITY_SENTENCE_CHRF,
                     UTILITY_SENTENCE_CHRF_BALANCED,
                     UTILITY_SENTENCE_BLEU_SYMMETRIC,
                     UTILITY_SENTENCE_BLEU_FLOOR_SYMMETRIC,
                     UTILITY_SENTENCE_BLEU_ADD_K_SYMMETRIC,
                     UTILITY_SENTENCE_BLEU_EXP_SYMMETRIC,
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
    parser.add_argument("--references", type=str, help="Reference translations, one translation per line. If given,"
                                                       "perform MBR in oracle mode.",
                        required=False, default=None)

    args = parser.parse_args()

    return args


class MBR(object):

    def __init__(self,
                 utility_function_name: str,
                 symmetric: bool = False) -> None:
        """

        :param utility_function_name:
        :param symmetric:
        """
        self.cached_scorer = None
        self.scorer = None
        self.args = None

        self.utility_function_name = utility_function_name
        self.symmetric = symmetric

        self.create_scorer()

    def create_scorer(self) -> None:
        """

        :return:
        """
        if "chrf" in self.utility_function_name:
            if self.utility_function_name.endswith("balanced"):
                chrf_beta = 1
            else:
                chrf_beta = 2

            self.args = argparse.Namespace(chrf_order=6, chrf_beta=chrf_beta, chrf_whitespace=False, short=False)

            self.scorer = cached_metrics.CachedCHRF(self.args)
            self.cached_scorer = True

        elif "bleu" in self.utility_function_name:
            if self.utility_function_name.endswith("floor"):
                smooth_method = "floor"
                smooth_value = 0.01
            elif self.utility_function_name.endswith("exp"):
                smooth_method = "exp"
                smooth_value = None
            elif self.utility_function_name.endswith("add-k"):
                smooth_method = "add-k"
                smooth_value = 1
            else:
                smooth_method = "none"
                smooth_value = None

            self.args = argparse.Namespace(smooth_method=smooth_method, smooth_value=smooth_value, force=False,
                                           short=False, lc=False, tokenize=DEFAULT_TOKENIZER)

            self.scorer = cached_metrics.CachedBLEU(self.args)
            self.cached_scorer = True

        elif self.utility_function_name == "sentence-ter":

            self.args = argparse.Namespace(normalized=False, no_punct=False,
                                           asian_support=False, case_sensitive=False)
            self.scorer = TER(self.args)
            self.cached_scorer = False

        else:
            if self.utility_function_name.endswith("balanced"):
                meteor_alpha = 0.5
            else:
                meteor_alpha = 0.85

            self.scorer = eval_meteor.MeteorScorer(meteor_alpha=meteor_alpha)
            self.cached_scorer = False

    def score_single(self, hyp: str, ref: str) -> float:
        """
        Computes a single score between two strings.

        :param hyp:
        :param ref:
        :return:
        """
        return self.scorer.sentence_score(hyp, [ref]).score

    def score(self, hyp: str, ref: str) -> Union[float, np.ndarray]:
        """

        :param hyp:
        :param ref:
        :return:
        """

        if self.symmetric:
            return self.score_symmetric(hyp, ref)

        return self.score_single(hyp, ref)

    def score_symmetric(self, hyp: str, ref: str) -> np.ndarray:
        """

        :param hyp:
        :param ref:
        :return:
        """
        forward = self.score_single(hyp, ref)
        backward = self.score_single(ref, hyp)

        # harmonic mean of forward and backward values

        return stats.hmean([forward, backward])

    def get_maximum_utility_sample(self,
                                   samples: List[str],
                                   reference: Optional[str] = None) -> Tuple[str, float]:
        """

        :param samples: Sampled target translations for one single source input sentence
        :param reference: Actual reference translation to compare to samples (oracle mode).

        :return: The best-performing sample and its utility score.
        """

        average_utilities = []

        for sample in samples:

            if reference is None:

                # without reference, compute mean utility among pool of samples

                utilities = []

                for pseudo_reference in samples:
                    utility = self.score(sample, pseudo_reference)
                    utilities.append(utility)

                if len(utilities) == 0:
                    average_utility = 0.0
                else:
                    average_utility = np.mean(utilities)
            else:
                # with reference, operate in oracle mode and compare to the actual reference

                average_utility = self.score(sample, reference)

            average_utilities.append(average_utility)

        maximum_utility_index = int(np.argmax(average_utilities))

        return samples[maximum_utility_index], np.max(average_utilities)

    def cache_info(self) -> None:
        """

        :return:
        """
        if self.cached_scorer:
            logging.debug("Scorer cache:")
            logging.debug(self.scorer.cache_info())

    def cache_clear(self) -> None:
        """

        :return:
        """
        if self.cached_scorer:
            self.scorer.cache_clear()


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handle = open(args.input, "r")
    output_handle = open(args.output, "w")

    if args.references is not None:
        ref_handle = open(args.references, "r")
        zip_function = zip
    else:
        ref_handle = []
        zip_function = itertools.zip_longest

    input_handles = [input_handle, ref_handle]

    if "symmetric" in args.utility_function:
        symmetric_utility = True
        utility_function_name = args.utility_function.replace("-symmetric", "")
    else:
        symmetric_utility = False
        utility_function_name = args.utility_function

    mbr_decoder = MBR(utility_function_name=utility_function_name,
                      symmetric=symmetric_utility)

    for line_index, line_tuple in enumerate(zip_function(*input_handles)):

        input_line, ref_line = line_tuple

        # new scorer cache for each set of samples

        mbr_decoder.cache_clear()

        jobj = json.loads(input_line)
        samples = jobj["translations"]

        if args.num_samples > -1:
            samples = samples[args.sample_start_index:args.num_samples]
            assert len(samples) >= args.num_samples, "Slicing with --sample-start-index selected " \
                                                     "fewer translations than --num-samples!"

        # remove samples if they are the empty string or whitespace-only

        samples = [sample for sample in samples if sample.strip() != ""]

        # in dry run mode, do actual computation for the first example, then toy numbers

        if args.dry_run and line_index > 0:
            output, utility = samples[0], 0.0
        else:
            output, utility = mbr_decoder.get_maximum_utility_sample(samples=samples, reference=ref_line)

        # always log cache info for dry run

        if args.dry_run:
            mbr_decoder.cache_info()

        output = output.strip()
        output_handle.write("%f\t%s\n" % (utility, output))

    # log contents of last cache if not dry run

    if not args.dry_run:
        mbr_decoder.cache_info()


if __name__ == "__main__":
    main()
