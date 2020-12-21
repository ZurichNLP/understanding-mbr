#! /usr/bin/python3

import json
import logging
import argparse

from typing import List, Tuple
from itertools import zip_longest
from collections import Counter


HEADER = """<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta charset="UTF-8">
<style>
table {
    border-collapse: collapse;
    border-spacing: 0;
    width: 100%;
    border: 1px solid #ddd;
    margin-bottom: 10px;
}
tr:nth-child(even) {
    background-color: #f2f2f2
}

.copy {
    background-color: #FFB6C1 !important;
}

.hallucination {
    background-color: #ADD8E6 !important;
}

th, td {
    text-align: left;
    padding: 16px;
}
</style>
</head>
<body>
"""

COLUMN_HEADERS = ["ID", "SUB ID", "SOURCE", "HYPOTHESIS", "REFERENCE", "UTILITY", "OVERLAP_SOURCE",
                  "OVERLAP_REFERENCE_WORD", "OVERLAP_REFERENCE_BLEU2"]

FOOTER = """
</body>
</html>"""


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--source", type=str, help="Path to source translations.", required=True)
    parser.add_argument("--reference", type=str, help="Path to reference translations", required=True)
    parser.add_argument("--nbest", type=str, help="Path to nbest translations with risk scores and overlaps,"
                                                  "one JSON per line.", required=True)

    parser.add_argument("--highlight-threshold-copy", type=float, help="Threshold to highlight hypotheses as copies.",
                        required=False, default=0.9)
    parser.add_argument("--highlight-threshold-hallucination", type=float, help="Threshold to highlight hypotheses as "
                                                                                "hallucinations.",
                        required=False, default=0.01)
    parser.add_argument("--highlight-type-hallucination", type=str, help="Which overlap value to use for coloring"
                                                                         "hallucination cells",
                        required=False, default="bleu-2", choices=["word", "bleu-2"])

    args = parser.parse_args()

    return args


def truncate_if_float(input_string: str) -> str:
    """

    :param input_string:
    :return:
    """

    try:
        as_float = float(input_string)
    except ValueError:
        return input_string

    if as_float.is_integer():
        return input_string

    return "%.5f" % as_float


class TableCreator(object):

    def __init__(self,
                 highlight_threshold_copy: float,
                 highlight_threshold_hallucination: float,
                 highlight_type_hallucination: str) -> None:
        """

        :param highlight_threshold_copy:
        :param highlight_threshold_hallucination:
        :param highlight_type_hallucination:
        """

        self.highlight_threshold_copy = highlight_threshold_copy
        self.highlight_threshold_hallucination = highlight_threshold_hallucination
        self.highlight_type_hallucination = highlight_type_hallucination

    def get_class_string(self,
                         overlap_with_source: float,
                         overlap_with_reference_word: float,
                         overlaps_with_reference_bleu2: float) -> Tuple[str, str]:
        """

        :param overlap_with_source:
        :param overlap_with_reference_word:
        :param overlaps_with_reference_bleu2:
        :return:
        """

        if overlap_with_source >= self.highlight_threshold_copy:
            return ' class="copy"', "copy"

        if self.highlight_type_hallucination == "word":
            compare_to = overlap_with_reference_word
        else:
            compare_to = overlaps_with_reference_bleu2

        if compare_to <= self.highlight_threshold_hallucination:
            return ' class="hallucination"', "hallucination"

        return "", "normal"

    def create_table(self,
                     line_index: int,
                     nbest_line: str,
                     source_line: str,
                     reference_line: str) -> Counter:
        """

        :param line_index:
        :param nbest_line:
        :param source_line:
        :param reference_line:
        :return:
        """

        print("<table>")

        print("<thead>")
        print("  <tr>")
        for column_header in COLUMN_HEADERS:
            print("    <th>%s</th>" % column_header)
        print("  </tr>")
        print("</thead>")

        print("<tbody>")

        jobj = json.loads(nbest_line)
        translations = jobj["translations"]  # type: List[str]
        utilities = jobj["utilities"]  # type: List[float]
        overlaps_with_source = jobj["overlaps_with_source"]  # type: List[float]
        overlaps_with_reference_word = jobj["overlaps_with_reference_word"]  # type: List[float]
        overlaps_with_reference_bleu2 = jobj["overlaps_with_reference_bleu2"]  # type: List[float]

        lists = [translations, utilities, overlaps_with_source, overlaps_with_reference_word, overlaps_with_reference_bleu2]

        counts = Counter()

        for sub_index, value_tuple in enumerate(zip_longest(*lists)):

            if None in value_tuple:
                break

            # noinspection PyTupleAssignmentBalance
            hypothesis, utility, overlap_with_source, overlap_with_reference_word, overlap_with_reference_bleu2 = value_tuple

            class_string, hyp_type = self.get_class_string(overlap_with_source, overlap_with_reference_word,
                                                           overlap_with_reference_bleu2)

            counts[hyp_type] += 1

            print("  <tr%s>" % class_string)

            cell_items = [line_index, sub_index, source_line, hypothesis, reference_line, utility, overlap_with_source,
                          overlap_with_reference_word, overlap_with_reference_bleu2]

            cell_items = [truncate_if_float(c) for c in cell_items]

            for cell_item in cell_items:
                cell_item = str(cell_item)
                print("    <td>%s</td>" % cell_item)

            print("  </tr>")

        print("</tbody>")

        print("</table>")

        return counts


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    print(HEADER)

    source_handle = open(args.source, "r")
    reference_handle = open(args.reference, "r")
    nbest_handle = open(args.nbest, "r")

    table_creator = TableCreator(highlight_threshold_copy=args.highlight_threshold_copy,
                                 highlight_threshold_hallucination=args.highlight_threshold_hallucination,
                                 highlight_type_hallucination=args.highlight_type_hallucination)

    counts = Counter()

    for line_index, line_tuple in enumerate(zip(source_handle, reference_handle, nbest_handle)):
        line_tuple = [l.strip() for l in line_tuple]
        source_line, reference_line, nbest_line = line_tuple

        counts_per_table = table_creator.create_table(line_index, nbest_line, source_line, reference_line)
        counts = counts + counts_per_table

    print(FOOTER)

    logging.debug("Overall counts:")
    logging.debug(counts)


if __name__ == '__main__':
    main()
