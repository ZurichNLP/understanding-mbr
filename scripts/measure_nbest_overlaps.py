#! /usr/bin/python3

import json
import argparse
import logging

# local dependency

# noinspection PyUnresolvedReferences
from measure_overlaps import Measurer, OVERLAP_FUNCTIONS


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--source", type=str, help="Path to sentences to compare against.", required=True)
    parser.add_argument("--reference", type=str, help="Path to sentences to compare against.", required=True)
    parser.add_argument("--nbest-input", type=str, help="Path to nbest list of translations with risk scores, as JSON.",
                        required=True)

    parser.add_argument("--output", type=str, help="Where to save numpy array of overlaps.", required=True)

    args = parser.parse_args()

    return args


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    measurers = {"word": Measurer(overlap_function="word"),
                 "bleu2": Measurer(overlap_function="bleu-2"),
                 "chrf": Measurer(overlap_function="chrf")}

    source_handle = open(args.source, "r")
    reference_handle = open(args.reference, "r")
    nbest_handle = open(args.nbest_input, "r")

    output_handle = open(args.output, "w")

    for source_line, reference_line, nbest_line in zip(source_handle, reference_handle, nbest_handle):

        jobj = json.loads(nbest_line)
        translations = jobj["translations"]

        overlaps_with_source = []
        overlaps_with_reference = {"word": [], "bleu2": [], "chrf": []}

        for translation in translations:

            overlap_with_source = measurers["word"].measure(translation, source_line)
            overlaps_with_source.append(overlap_with_source)

            for overlap_function in OVERLAP_FUNCTIONS:
                overlap_with_reference = measurers[overlap_function].measure(translation, reference_line)
                overlaps_with_reference[overlap_function].append(overlap_with_reference)

        jobj["overlaps_with_source"] = overlaps_with_source

        for overlap_function in OVERLAP_FUNCTIONS:
            jobj["overlaps_with_reference_%s" % overlap_function] = overlaps_with_reference[overlap_function]

        output_handle.write(json.dumps(jobj) + "\n")


if __name__ == '__main__':
    main()
