#! /usr/bin/python3

import argparse
import logging
import json

import numpy as np


OVERLAP_FUNCTIONS = ["word", "bleu2", "chrf"]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--nbest-input", type=str, help="Path to nbest list of translations with risk scores "
                                                        "and overlaps, as JSON.",
                        required=True)

    parser.add_argument("--nbest-output", type=str, help="Where to save JSON results.", required=True)

    parser.add_argument("--threshold-copy", type=float, help="Threshold above which to classify as copies.",
                        required=False, default=0.9)
    parser.add_argument("--threshold-hallucination", type=float, help="Threshold below which to classify as"
                                                                      "hallucination.",
                        required=False, default=0.01)
    parser.add_argument("--overlap-function-reference", type=str, help="Overlap function to extract for reference.",
                        required=True, choices=OVERLAP_FUNCTIONS)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    nbest_handle = open(args.nbest_input, "r")

    output_handle = open(args.nbest_output, "w")

    output_jobj = {"copy": 0,
                   "hallucination": 0,
                   "all": 0,
                   "threshold_copy": args.threshold_copy,
                   "threshold_hallucination": args.threshold_hallucination
                   }

    average_utilities_all = []
    average_utilities_copy = []
    average_utilities_hallucination = []

    for nbest_line in nbest_handle:

        jobj = json.loads(nbest_line)

        overlaps_with_source = jobj["overlaps_with_source"]
        overlaps_with_reference = jobj["overlaps_with_reference_%s" % args.overlap_function_reference]
        utilities = jobj["utilities"]

        utilities_copy = []
        utilities_hallucination = []

        for overlap_source, overlap_reference, utility in zip(overlaps_with_source, overlaps_with_reference, utilities):

            if overlap_source > args.threshold_copy:
                utilities_copy.append(utility)
                output_jobj["copy"] += 1

            if overlap_reference < args.threshold_hallucination:
                utilities_hallucination.append(utility)
                output_jobj["hallucination"] += 1

            output_jobj["all"] += 1

        average_utilities_all.append(np.mean(utilities))

        if len(utilities_copy) > 0:
            average_utilities_copy.append(np.mean(utilities_copy))

        if len(utilities_hallucination) > 0:
            average_utilities_hallucination.append(np.mean(utilities_hallucination))

    output_jobj["average_utilities_all"] = average_utilities_all
    output_jobj["average_average_utilities_copy"] = average_utilities_copy
    output_jobj["average_average_utilities_hallucination"] = average_utilities_hallucination

    output_jobj["average_average_utilities_all"] = np.mean(average_utilities_all)
    output_jobj["average_average_utilities_copy"] = np.mean(average_utilities_copy)
    output_jobj["average_average_utilities_hallucination"] = np.mean(average_utilities_hallucination)

    output_handle.write(json.dumps(output_jobj) + "\n")


if __name__ == '__main__':
    main()
