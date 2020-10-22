#! /usr/bin/python3

import argparse
import logging
import json

import numpy as np

from scipy import stats
from typing import Tuple, List, Union
from methodtools import lru_cache
from collections import Counter
from sacrebleu import CHRF, BLEU, TER, DEFAULT_TOKENIZER

# local dependency

import eval_meteor


UTILITY_SENTENCE_BLEU = "sentence-bleu"
UTILITY_SENTENCE_METEOR = "sentence-meteor"
UTILITY_SENTENCE_TER = "sentence-ter"
UTILITY_SENTENCE_CHRF = "sentence-chrf"
UTILITY_SENTENCE_CHRF_BALANCED = "sentence-chrf-balanced"

UTILITY_SENTENCE_BLEU_SYMMETRIC = "sentence-bleu-symmetric"
UTILITY_SENTENCE_METEOR_SYMMETRIC = "sentence-meteor-symmetric"
UTILITY_SENTENCE_TER_SYMMETRIC = "sentence-ter-symmetric"
UTILITY_SENTENCE_CHRF_SYMMETRIC = "sentence-chrf-symmetric"

UTILITY_FUNCTIONS = [UTILITY_SENTENCE_BLEU,
                     UTILITY_SENTENCE_METEOR,
                     UTILITY_SENTENCE_TER,
                     UTILITY_SENTENCE_CHRF,
                     UTILITY_SENTENCE_CHRF_BALANCED,
                     UTILITY_SENTENCE_BLEU_SYMMETRIC,
                     UTILITY_SENTENCE_METEOR_SYMMETRIC,
                     UTILITY_SENTENCE_TER_SYMMETRIC,
                     UTILITY_SENTENCE_CHRF_SYMMETRIC]


class CachedCHRF(CHRF):

    @lru_cache(maxsize=128)
    def extract_char_ngrams(self, s: str, n: int) -> Counter:
        """
        Yields counts of character n-grams from string s of order n.
        """
        return Counter([s[i:i + n] for i in range(len(s) - n + 1)])

    def cache_info(self):
        return self.extract_char_ngrams.cache_info()

    def cache_clear(self):
        return self.extract_char_ngrams.cache_clear()


class CachedBLEU(BLEU):

    @lru_cache(maxsize=128)
    def extract_ngrams(self, line, min_order=1, max_order=BLEU.NGRAM_ORDER) -> Counter:
        """Extracts all the ngrams (min_order <= n <= max_order) from a sequence of tokens.
        :param line: A segment containing a sequence of words.
        :param min_order: Minimum n-gram length (default: 1).
        :param max_order: Maximum n-gram length (default: NGRAM_ORDER).
        :return: a dictionary containing ngrams and counts
        """

        ngrams = Counter()  # type: Counter
        tokens = line.split()
        for n in range(min_order, max_order + 1):
            for i in range(0, len(tokens) - n + 1):
                ngram = ' '.join(tokens[i: i + n])
                ngrams[ngram] += 1

        return ngrams

    def cache_info(self):
        return self.extract_ngrams.cache_info()

    def cache_clear(self):
        return self.extract_ngrams.cache_clear()


# variable needs to be instantiated globally because of a limitation of METEOR external java processes

SCORER_METEOR = eval_meteor.MeteorScorer()


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


class MBR(object):

    def __init__(self,
                 utility_function_name: str,
                 symmetric: bool = False) -> None:
        """

        :param utility_function_name:
        :param symmetric:
        """
        self.cached = None
        self.scorer = None

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

            args_chrf = argparse.Namespace(chrf_order=6, chrf_beta=chrf_beta, chrf_whitespace=True, short=False)

            self.scorer = CachedCHRF(args_chrf)
            self.cached = True

        elif self.utility_function_name == "sentence-bleu":
            args_bleu = argparse.Namespace(smooth_method="floor", smooth_value=None, force=False,
                                           short=False, lc=False, tokenize=DEFAULT_TOKENIZER)

            self.scorer = CachedBLEU(args_bleu)
            self.cached = True

        elif self.utility_function_name == "sentence-ter":

            args_ter = argparse.Namespace(normalized=False, no_punct=False,
                                          asian_support=False, case_sensitive=False)
            self.scorer = TER(args_ter)
            self.cached = False

        else:
            self.scorer = SCORER_METEOR
            self.cached = False

    def score(self, hyp: str, ref: str) -> Union[float, np.ndarray]:
        """
        Computes a single score between two strings.

        :param hyp:
        :param ref:
        :return:
        """
        if self.symmetric:
            return self.score_symmetric(hyp, ref)

        return self.scorer.sentence_score(hyp, [ref]).score

    def score_symmetric(self, hyp: str, ref: str) -> np.ndarray:
        """

        :param hyp:
        :param ref:
        :return:
        """
        forward = self.score(hyp, ref)
        backward = self.score(ref, hyp)

        # harmonic mean of forward and backward values

        return stats.hmean([forward, backward])

    def get_maximum_utility_sample(self,
                                   samples: List[str]) -> Tuple[str, float]:
        """

        :param samples: Sampled target translations for one single source input sentence

        :return:
        """

        average_utilities = []

        for sample in samples:

            utilities = []

            for pseudo_reference in samples:
                utility = self.score(sample, pseudo_reference)
                utilities.append(utility)

            if len(utilities) == 0:
                average_utility = 0.0
            else:
                average_utility = np.mean(utilities)

            average_utilities.append(average_utility)

        maximum_utility_index = int(np.argmax(average_utilities))

        return samples[maximum_utility_index], np.max(average_utilities)

    def cache_info(self) -> None:
        """

        :return:
        """
        if self.cached:
            logging.debug(self.scorer.cache_info())

    def cache_clear(self) -> None:
        """

        :return:
        """
        if self.cached:
            logging.debug(self.scorer.cache_clear())


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handle = open(args.input, "r")
    output_handle = open(args.output, "w")

    if "symmetric" in args.utility_function:
        symmetric_utility = True
        utility_function_name = args.utility_function.replace("-symmetric", "")
    else:
        symmetric_utility = False
        utility_function_name = args.utility_function

    mbr_decoder = None

    for line_index, line in enumerate(input_handle):

        # try to garbage collect actively to delete cache

        mbr_decoder.cache_clear()

        # new MBR object for each set of samples, for caching

        mbr_decoder = MBR(utility_function_name=utility_function_name,
                          symmetric=symmetric_utility)

        jobj = json.loads(line)
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
            output, utility = mbr_decoder.get_maximum_utility_sample(samples=samples)

            # always log cache info for dry run

            mbr_decoder.cache_info()

        output = output.strip()
        output_handle.write("%f\t%s\n" % (utility, output))

    # log contents of last cache

    logging.debug("Last MBR decoder cache info, if scorer is cached:")

    mbr_decoder.cache_info()


if __name__ == "__main__":
    main()
