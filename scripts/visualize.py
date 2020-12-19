#! /usr/bin/python3

import json
import logging
import argparse

from typing import List


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
}

th, td {
    text-align: left;
    padding: 16px;
}

tr:nth-child(even) {
    background-color: #f2f2f2
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

    parser.add_argument("--highlight-threshold-copies", type=float, help="Threshold to label hypotheses as copies.",
                        required=False, default=0.9)
    parser.add_argument("--highlight-threshold-hallucination", type=float, help="Threshold to label hypotheses as "
                                                                                "hallucinations.",
                        required=False, default=0.01)
    parser.add_argument("--highlight", type=str, help="Which overlap value to use for coloring cells",
                        required=False, default="OVERLAP_SOURCE", choices=["OVERLAP_SOURCE", "OVERLAP_REFERENCE_WORD",
                                                                           "OVERLAP_REFERENCE_BLEU2"])

    args = parser.parse_args()

    return args


def create_table(line_index: int,
                 nbest_line: str,
                 source_line: str,
                 reference_line: str) -> None:
    """

    :param line_index:
    :param nbest_line:
    :param source_line:
    :param reference_line:
    :return:
    """

    print("<table>")

    print("  <tr>")
    for column_header in COLUMN_HEADERS:
        print("    <th>%s</th>" % column_header)
    print("  </tr>")

    jobj = json.loads(nbest_line)
    translations = jobj["translations"]  # type: List[str]
    utilities = jobj["utilities"]  # type: List[float]
    overlaps_with_source = jobj["overlaps_with_source"]  # type: List[float]
    overlaps_with_reference_word = jobj["overlaps_with_reference_word"]  # type: List[float]
    overlaps_with_reference_bleu2 = jobj["overlaps_with_reference_bleu2"]  # type: List[float]

    lists = [translations, utilities, overlaps_with_source, overlaps_with_reference_word, overlaps_with_reference_bleu2]

    for sub_index, value_tuple in enumerate(zip(*lists)):
        # noinspection PyTupleAssignmentBalance
        hypothesis, utility, overlap_with_source, overlap_with_reference_word, overlap_with_reference_bleu2 = value_tuple

        print("  <tr>")

        cell_items = [line_index, sub_index, source_line, hypothesis, reference_line, utility, overlap_with_source,
                      overlap_with_reference_word, overlap_with_reference_bleu2]

        for cell_item in cell_items:
            cell_item = str(cell_item)
            print("    <td>%s</td>" % cell_item)

        print("  </tr>")

    print("</table>")


def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    print(HEADER)

    source_handle = open(args.source, "r")
    reference_handle = open(args.reference, "r")
    nbest_handle = open(args.nbest, "r")

    for line_index, line_tuple in enumerate(zip(source_handle, reference_handle, nbest_handle)):
        line_tuple = [l.strip() for l in line_tuple]
        source_line, reference_line, nbest_line = line_tuple

        create_table(line_index, nbest_line, source_line, reference_line)

        print("<hr>")

    print(FOOTER)


if __name__ == '__main__':
    main()
