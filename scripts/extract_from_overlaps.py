#! /usr/bin/python3

import numpy
import argparse
import logging
import json


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--overlaps-source", type=str, help="Path to numpy array of overlaps.", required=True)
    parser.add_argument("--overlaps-reference", type=str, help="Path to numpy array of overlaps.", required=True)

    parser.add_argument("--output", type=str, help="Where to save JSON results.", required=True)
    parser.add_argument("--threshold-copy", type=float, help="Threshold above which to classify as copies.",
                        required=False, default=0.9)
    parser.add_argument("--threshold-hallucination", type=float, help="Threshold below which to classify as"
                                                                      "hallucination.",
                        required=False, default=0.01)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    overlaps_source = numpy.load(args.overlaps_source)
    overlaps_reference = numpy.load(args.overlaps_reference)

    jobj = {"all": 0, "copy": 0, "hallucination": 0,
            "threshold_copy": args.threshold_copy,
            "threshold_hallucination": args.threshold_hallucination
            }

    num_hypotheses = len(overlaps_source)

    for index in range(num_hypotheses):
        overlap_source = overlaps_source[index]
        overlap_reference = overlaps_reference[index]

        if overlap_source > args.threshold_copy:
            jobj["copy"] += 1

        if overlap_reference < args.threshold_hallucination:
            jobj["hallucination"] += 1

    jobj["all"] = num_hypotheses

    with open(args.output, "w") as output_handle:
        output_handle.write(json.dumps(jobj) + "\n")


if __name__ == '__main__':
    main()
