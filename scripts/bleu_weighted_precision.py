#! /usr/bin/python3

import math
import sacrebleu

from sacrebleu import BLEU, BLEUScore
from typing import List, Optional, Iterable, Union
from itertools import zip_longest


class WeightedBLEU(BLEU):

    def __init__(self, args):
        super().__init__(args)
        self.precision_weights = args.precision_weights

        # Sanity check
        assert self.smooth_method in self.SMOOTH_DEFAULTS.keys(), \
            "Unknown smooth_method '{}'".format(self.smooth_method)

    @staticmethod
    def compute_bleu(correct: List[int],
                     total: List[int],
                     sys_len: int,
                     ref_len: int,
                     smooth_method: str = 'none',
                     smooth_value=None,
                     use_effective_order=False,
                     precision_weights: Optional[List[float]] = None) -> BLEUScore:
        """Computes BLEU score from its sufficient statistics. Adds smoothing.
        Smoothing methods (citing "A Systematic Comparison of Smoothing Techniques for Sentence-Level BLEU",
        Boxing Chen and Colin Cherry, WMT 2014: http://aclweb.org/anthology/W14-3346)
        - exp: NIST smoothing method (Method 3)
        - floor: Method 1
        - add-k: Method 2 (generalizing Lin and Och, 2004)
        - none: do nothing.
        :param correct: List of counts of correct ngrams, 1 <= n <= NGRAM_ORDER
        :param total: List of counts of total ngrams, 1 <= n <= NGRAM_ORDER
        :param sys_len: The cumulative system length
        :param ref_len: The cumulative reference length
        :param smooth_method: The smoothing method to use
        :param smooth_value: The smoothing value for `floor` and `add-k` methods. `None` falls back to default value.
        :param use_effective_order: If true, use the length of `correct` for the n-gram order instead of NGRAM_ORDER.
        :param precision_weights: Weights for ngram precisions.
        :return: A BLEU object with the score (100-based) and other statistics.
        """
        assert smooth_method in BLEU.SMOOTH_DEFAULTS.keys(), \
            "Unknown smooth_method '{}'".format(smooth_method)

        # Fetch the default value for floor and add-k
        if smooth_value is None:
            smooth_value = BLEU.SMOOTH_DEFAULTS[smooth_method]

        precisions = [0.0 for _ in range(BLEU.NGRAM_ORDER)]

        smooth_mteval = 1.
        effective_order = BLEU.NGRAM_ORDER
        for n in range(1, BLEU.NGRAM_ORDER + 1):
            if smooth_method == 'add-k' and n > 1:
                correct[n - 1] += smooth_value
                total[n - 1] += smooth_value
            if total[n - 1] == 0:
                break

            if use_effective_order:
                effective_order = n

            if correct[n - 1] == 0:
                if smooth_method == 'exp':
                    smooth_mteval *= 2
                    precisions[n - 1] = 100. / (smooth_mteval * total[n - 1])
                elif smooth_method == 'floor':
                    precisions[n - 1] = 100. * smooth_value / total[n - 1]
            else:
                precisions[n - 1] = 100. * correct[n - 1] / total[n - 1]

        # If the system guesses no i-grams, 1 <= i <= NGRAM_ORDER, the BLEU
        # score is 0 (technically undefined). This is a problem for sentence
        # level BLEU or a corpus of short sentences, where systems will get
        # no credit if sentence lengths fall under the NGRAM_ORDER threshold.
        # This fix scales NGRAM_ORDER to the observed maximum order.
        # It is only available through the API and off by default

        if sys_len < ref_len:
            bp = math.exp(1 - ref_len / sys_len) if sys_len > 0 else 0.0
        else:
            bp = 1.0

        if precision_weights is None:
            weighted_precisions = precisions
            score_denominator = effective_order
        else:
            weighted_precisions = []

            # ensure that if references are of length 1, the score has a maximum of 100

            if effective_order == 1:
                precision_weights = [1.0]

            for weight, precision in zip(precision_weights[:effective_order], precisions[:effective_order]):
                weighted_precisions.append(weight * sacrebleu.utils.my_log(precision))

            score_denominator = 1.0

        score = bp * math.exp(
            sum(weighted_precisions) / score_denominator)

        return BLEUScore(
            score, correct, total, precisions, bp, sys_len, ref_len)

    def corpus_score(self, sys_stream: Union[str, Iterable[str]],
                     ref_streams: Union[str, List[Iterable[str]]],
                     use_effective_order: bool = False) -> BLEUScore:
        """Produces BLEU scores along with its sufficient statistics from a source against one or more references.
        :param sys_stream: The system stream (a sequence of segments)
        :param ref_streams: A list of one or more reference streams (each a sequence of segments)
        :param use_effective_order: Account for references that are shorter than the largest n-gram.
        :return: a `BLEUScore` object containing everything you'd want
        """

        # Add some robustness to the input arguments
        if isinstance(sys_stream, str):
            sys_stream = [sys_stream]

        if isinstance(ref_streams, str):
            ref_streams = [[ref_streams]]

        sys_len = 0
        ref_len = 0

        correct = [0 for _ in range(self.NGRAM_ORDER)]
        total = [0 for _ in range(self.NGRAM_ORDER)]

        # look for already-tokenized sentences
        tokenized_count = 0

        fhs = [sys_stream] + ref_streams
        for lines in zip_longest(*fhs):
            if None in lines:
                raise EOFError("Source and reference streams have different lengths!")

            if self.lc:
                lines = [x.lower() for x in lines]

            if not (self.force or self.tokenizer.signature() == 'none') and lines[0].rstrip().endswith(' .'):
                tokenized_count += 1

            output, *refs = [self.tokenizer(x.rstrip()) for x in lines]

            output_len = len(output.split())
            ref_ngrams, closest_diff, closest_len = BLEU.reference_stats(refs, output_len)

            sys_len += output_len
            ref_len += closest_len

            sys_ngrams = BLEU.extract_ngrams(output)
            for ngram in sys_ngrams.keys():
                n = len(ngram.split())
                correct[n - 1] += min(sys_ngrams[ngram], ref_ngrams.get(ngram, 0))
                total[n - 1] += sys_ngrams[ngram]

        # Get BLEUScore object
        score = self.compute_bleu(
            correct, total, sys_len, ref_len,
            smooth_method=self.smooth_method, smooth_value=self.smooth_value,
            use_effective_order=use_effective_order,
            precision_weights=self.precision_weights)

        return score
