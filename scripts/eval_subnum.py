#! /usr/bin/python3

import argparse
import logging

import nltk
import sacrebleu

import numpy as np

from typing import List


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--ref", type=str, help="Reference translations", required=True)
    parser.add_argument("--hyp", type=str, help="Hypotheses for all modified inputs.", required=True)
    parser.add_argument("--num", type=str, help="File listing counts of variations per reference sentence.",
                        required=True)

    args = parser.parse_args()

    return args


def compute_ratio(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """
    # naive tokenization
    hyp_len = len(hyp.split(" "))
    ref_len = len(ref.split(" "))

    return hyp_len / ref_len


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

    return sacrebleu.sentence_ter(hyp, ref).score


def compute_bleu(hyp: str, ref: str) -> float:
    """

    :param hyp:
    :param ref:
    :return:
    """

    return sacrebleu.sentence_bleu(hyp, [ref]).score


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


def compute_range_average(score_ranges: List[List[float]]) -> List[float]:
    """

    :param score_ranges:
    :return:
    """
    bleu_ranges = [s[0] for s in score_ranges]
    ter_ranges = [s[1] for s in score_ranges]
    meteor_ranges = [s[2] for s in score_ranges]
    ratio_ranges = [s[3] for s in score_ranges]

    all_ranges = [bleu_ranges, ter_ranges, meteor_ranges, ratio_ranges]

    return [float(np.mean(r)) for r in all_ranges]


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    num_handle = open(args.num, "r")
    ref_handle = open(args.ref, "r")
    hyp_handle = open(args.hyp, "r")

    print("BLEU\tTER\tMETEOR\tRATIO")

    seen = 0

    score_ranges = []

    for num_line, ref_line in zip(num_handle, ref_handle):

        ref_line = ref_line.strip()
        num = int(num_line.strip())

        if num == 0:
            continue

        accumulated = []

        for _ in range(num):
            hyp_line = hyp_handle.readline()
            hyp_line = hyp_line.strip()
            accumulated.append(hyp_line)

        score_range = compute_ranges(accumulated, ref_line)

        score_ranges.append(score_range)

        seen += 1

        if seen % 10000 == 0:
            logging.debug("Seen %d sentences." % seen)

    range_averages = compute_range_average(score_ranges)
    range_averages = [str(r) for r in range_averages]

    logging.debug("RANGE AVERAGES:")
    logging.debug("BLEU\tTER\tMETEOR\tRATIO")
    logging.debug("\t".join(range_averages))

    for score_range in score_ranges:
        score_range = [str(s) for s in score_range]
        print("\t".join(score_range))


if __name__ == '__main__':
    main()
