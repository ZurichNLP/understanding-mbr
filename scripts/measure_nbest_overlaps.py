#! /usr/bin/python3

import json
import argparse
import logging

# local dependency

from measure_overlaps import Measurer


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

    m_word = Measurer(overlap_function="word")
    m_bleu2 = Measurer(overlap_function="bleu-2")

    source_handle = open(args.source, "r")
    reference_handle = open(args.reference, "r")
    nbest_handle = open(args.nbest_input, "r")

    output_handle = open(args.output, "w")

    for source_line, reference_line, nbest_line in zip(source_handle, reference_handle, nbest_handle):

        jobj = json.loads(nbest_line)
        translations = jobj["translations"]

        overlaps_with_source = []
        overlaps_with_reference_word = []
        overlaps_with_reference_bleu2 = []

        for translation in translations:

            overlap_with_source = m_word.measure(translation, source_line)
            overlap_with_reference_word = m_word.measure(translation, reference_line)
            overlap_with_reference_bleu2 = m_bleu2.measure(translation, reference_line)

            overlaps_with_source.append(overlap_with_source)
            overlaps_with_reference_word.append(overlap_with_reference_word)
            overlaps_with_reference_bleu2.append(overlap_with_reference_bleu2)

        jobj["overlaps_with_source"] = overlaps_with_source
        jobj["overlaps_with_reference_word"] = overlaps_with_reference_word
        jobj["overlaps_with_reference_bleu2"] = overlaps_with_reference_bleu2

        output_handle.write(json.dumps(jobj) + "\n")


if __name__ == '__main__':
    main()
