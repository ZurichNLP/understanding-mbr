#! /usr/bin/python3

import json
import logging
import argparse

from typing import List, Tuple, Optional
from itertools import zip_longest
from collections import Counter


HEADER = """<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta charset="UTF-8">
<style>
body {
    font-family: Helvetica Neue,Helvetica,Arial,sans-serif;
}

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

.copy.hallucination {
    background: linear-gradient(0deg, rgba(255,182,193,1) 0%, rgba(173,216,230,1) 100%);
}

div, p, input, select {
  font-size: 20px;
}

th, td {
    text-align: left;
    padding: 16px;
}
</style>
<script
  src="https://code.jquery.com/jquery-3.5.1.min.js"
  integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0="
  crossorigin="anonymous"></script>
<script>

  const textFieldChangedCopy = (e) => {
    const textField = $(e.currentTarget);
    const value = textField.val();
    
    $("tbody tr").each((i, row) => {
      const cellValue = parseFloat($("td:nth-child(7)", row).first().text());
      const copyCells = $("td:nth-child(3), td:nth-child(4), td:nth-child(7)", row);
      copyCells.toggleClass("copy", cellValue > value)
    });

    stats();
  };

  const textFieldChangedHallucination = (e) => {
    const textField = $(e.currentTarget);
    const value = textField.val();

    const hallucinationFunction = $("#function-hallucination option:selected").first().text();

    var cellValueIndex;

    if (hallucinationFunction === "word") {
      cellValueIndex = 8;
    } else if (hallucinationFunction === "bleu2") {
      cellValueIndex = 9;
    } else {
      cellValueIndex = 10;
    }

    $("tbody tr").each((i, row) => {
      const cellValue = parseFloat($(`td:nth-child(${cellValueIndex})`, row).first().text());

      const allCells = $("td", row);
      allCells.removeClass("hallucination");

      const copyCells = $(`td:nth-child(4), td:nth-child(5), td:nth-child(${cellValueIndex})`, row);
      copyCells.toggleClass("hallucination", cellValue < value)
    });

    stats();
  };

  const dropdownChanged = (e) => {
    // trigger textFieldChanged events
    $('#threshold-copy').trigger('keyup');
    $('#threshold-hallucination').trigger('keyup');
  };

  function stats() {

    const countNormal = $("tbody tr:not(:has(td[class]))").length;
    const countCopies = $("tr").has("td.copy:not(.hallucination)").length;
    const countHallucinations = $("tr").has("td.hallucination:not(.copy)").length;
    const countBoth = $("tr").has("td.copy.hallucination").length;
    const countAll = $("tbody tr").length;

    $("#count-normal").text(countNormal.toString());
    $("#count-copies").text(countCopies.toString());
    $("#count-hallucinations").text(countHallucinations.toString());
    $("#count-both").text(countBoth.toString());
    $("#count-all").text(countAll.toString());
  };

  const ResetClicked = (e) => {
    $("input[type=number]").each(function(){
      var $current = $(this);
      $current.val($current.data("original-value"))
    });

    $('select').prop('selectedIndex', 0);

    // trigger textFieldChanged events
    $('#threshold-copy').trigger('keyup');
    $('#threshold-hallucination').trigger('keyup');
  };

  $(document).ready(() => {
    $("#threshold-copy").bind('keyup', textFieldChangedCopy);
    $("#threshold-hallucination").bind('keyup', textFieldChangedHallucination);
    $("#function-hallucination").bind('change', dropdownChanged);
    $("#button-reset").bind('click', ResetClicked);
    stats();
    $("#button-reset").trigger('click');
  });
</script>
</head>
<body>
"""

INFO_TEMPLATE = """<h1>Info</h1>
<p>Source: {source}</p>
<p>Translations: {nbest}</p>
<p>Reference: {reference}</p>
<br>"""

HEADER2 = """<h1>Settings</h1>
<div>
  Highlight as <span class="copy">copies</span> if overlap with source larger than
  <input id="threshold-copy" type="number" value="0.9" data-original-value="0.9" step="any"/>
</div>
<br>
<div>
  Highlight as <span class="hallucination">hallucinations</span> if overlap with reference lower than
  <input id="threshold-hallucination" type="number" step="any" value="0.01" data-original-value="0.01"/>
</div>
<br>
<div>
  Highlight hallucinations with this overlap function: <select id="function-hallucination">
  <option value="chrf">chrf</option>
  <option value="bleu2">bleu2</option>
  <option value="word">word</option>
</select>
</div>
<br>
<input type="button" id="button-reset" value="Reset to default values">
<br>

<h1>Statistics</h1>
<p>Normal hypotheses: <span id="count-normal"/></p>
<p>Copies: <span id="count-copies"/></p>
<p>Hallucinations: <span id="count-hallucinations"/></p>
<p>Both (count not exclusive): <span id="count-both"/></p>
<p><strong>Total: <span id="count-all"/></strong></p>
<br>
<h1>Translations</h1>
<br>
"""

COLUMN_HEADERS = ["ID", "SUB ID", "SOURCE", "HYPOTHESIS", "REFERENCE", "UTILITY", "OVERLAP_SOURCE",
                  "OVERLAP_REFERENCE_WORD", "OVERLAP_REFERENCE_BLEU2", "OVERLAP_REFERENCE_CHRF"]

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
                        required=False, default="chrf", choices=["word", "bleu2", "chrf"])

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
                         overlaps_with_reference_bleu2: float,
                         overlaps_with_reference_chrf: float) -> Tuple[str, str]:
        """

        :param overlap_with_source:
        :param overlap_with_reference_word:
        :param overlaps_with_reference_bleu2:
        :param overlaps_with_reference_chrf:
        :return:
        """

        if overlap_with_source >= self.highlight_threshold_copy:
            return ' class="copy"', "copy"

        if self.highlight_type_hallucination == "word":
            compare_to = overlap_with_reference_word
        elif self.highlight_type_hallucination == "bleu2":
            compare_to = overlaps_with_reference_bleu2
        else:
            compare_to = overlaps_with_reference_chrf

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
        overlaps_with_reference_chrf = jobj["overlaps_with_reference_chrf"]  # type: List[Optional[float]]

        lists = [translations, utilities, overlaps_with_source,
                 overlaps_with_reference_word, overlaps_with_reference_bleu2, overlaps_with_reference_chrf]

        counts = Counter()

        for sub_index, value_tuple in enumerate(zip_longest(*lists)):

            if None in value_tuple:
                break

            # noinspection PyTupleAssignmentBalance
            hypothesis, utility, overlap_with_source, overlap_with_reference_word, overlap_with_reference_bleu2, \
                overlap_with_reference_chrf = value_tuple

            class_string, hyp_type = self.get_class_string(overlap_with_source, overlap_with_reference_word,
                                                           overlap_with_reference_bleu2, overlap_with_reference_chrf)

            counts[hyp_type] += 1

            print("  <tr>")

            cell_items = [line_index, sub_index, source_line, hypothesis, reference_line, utility, overlap_with_source,
                          overlap_with_reference_word, overlap_with_reference_bleu2, overlap_with_reference_chrf]

            highlight = [False for _ in cell_items]

            if hyp_type == "copy":
                highlight_indexes = [2, 3, 6]
            elif hyp_type == "hallucination":
                highlight_indexes = [3, 4]

                if self.highlight_type_hallucination == "word":
                    highlight_indexes.append(7)
                elif self.highlight_type_hallucination == "bleu2":
                    highlight_indexes.append(8)
                else:
                    highlight_indexes.append(9)
            else:
                highlight_indexes = []

            for h in highlight_indexes:
                highlight[h] = True

            cell_items = [str(truncate_if_float(c)) for c in cell_items]

            for cell_index, cell_item in enumerate(cell_items):

                if highlight[cell_index]:
                    print("    <td%s>%s</td>" % (class_string, cell_item))
                else:
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
    print(INFO_TEMPLATE.format(source=args.source, nbest=args.nbest, reference=args.reference))
    print(HEADER2)

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
