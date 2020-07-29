#! /usr/bin/python3

import argparse
import logging

import pyter
import nltk
import sacrebleu

import numpy as np

from typing import List


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--ref", type=str, help="Reference translations", required=True)
    parser.add_argument("--hyp", type=int, help="Hypotheses for all modified inputs.", default=64)
    parser.add_argument("--num-variations", type=int, help="How many variations per input sentence.", default=1)

    args = parser.parse_args()

    return args


def compute_ratio(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    return len(hyp) / len(ref)


def compute_meteor(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    return nltk.translate.meteor_score.single_meteor_score(ref, hyp)


def compute_ter(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    return pyter.ter(hyp, ref)


def compute_bleu(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_bleu(hyp, ref).score


def compute_range(scores: List[float]) -> float:
    """

    :param scores:
    :return:
    """
    return np.abs(np.max(scores) - np.min(scores))


def compute_ranges(accumulated: List[str], ref_line: str) -> List[float]:
    """

    :param accumulated:
    :param ref_line:
    :return:
    """
    bleu_scores = [compute_bleu(a, ref_line) for a in accumulated]
    ter_scores = [compute_ter(a, ref_line) for a in accumulated]
    meteor_scores = [compute_meteor(a, ref_line) for a in accumulated]
    ratios = [compute_ratio(a, ref_line) for a in accumulated]

    all_scores = [bleu_scores, ter_scores, meteor_scores, ratios]

    return [compute_range(s) for s in all_scores]


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    ref_handle = open(args.ref, "r")
    hyp_handle = open(args.hyp, "r")

    accumulated = []

    score_ranges = []

    for hyp_line in hyp_handle:
        hyp_line = hyp_line.strip()

        accumulated.append(hyp_line)

        if len(accumulated) == args.num_variations:
            ref_line = ref_handle.readline()
            ref_line = ref_line.strip()
            score_range = compute_ranges(accumulated, ref_line)
            score_ranges.append(score_range)

            accumulated = []

    for score_range in score_ranges:
        score_range = [str(s) for s in score_range]
        print("/t".join(score_range))


if __name__ == '__main__':
    main()
