#! /usr/bin/python3

import os
import argparse
import logging

from collections import defaultdict


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--eval-folder", type=str, help="Path that should be searched for results.")

    args = parser.parse_args()

    return args


def walklevel(some_dir, level=1):
    """
    Taken from:
    https://stackoverflow.com/a/234329/1987598

    :param some_dir:
    :param level:
    :return:
    """
    some_dir = some_dir.rstrip(os.path.sep)
    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        yield root, dirs, files
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            del dirs[:]


def parse_filename(filename: str):
    """

    :param filename:
    :return:
    """
    parts = filename.split(".")

    corpus, decoding_method = parts[0], parts[1]

    if filename.endswith("average"):
        metric = "subnum"
    else:
        metric = parts[2]

    return corpus, decoding_method, metric


def parse_bleu(filename: str) -> str:

    with open(filename, "r") as infile:
        line = infile.readline().strip()

        parts = line.split(" ")

    if len(parts) < 3:
        return "-"

    return parts[2]


def parse_meteor(filename: str) -> str:

    with open(filename, "r") as infile:
        line = infile.readline().strip()

    if line == "":
        return "-"

    return line


def parse_subnum_average(filename: str):

    with open(filename, "r") as infile:
        lines = infile.readlines()
        lines = [l.strip() for l in lines]

    parts = lines[-1].split("\t")

    bleu, ter, meteor, ratio = parts

    return bleu, ter, meteor, ratio


def parse_metric_values(metric, filepath):

    if metric == "bleu":
        metric_names = ["BLEU"]
        metric_values = [parse_bleu(filepath)]
    elif metric == "meteor":
        metric_names = ["METEOR"]
        metric_values = [parse_meteor(filepath)]
    else:
        metric_names = ["SUBNUM_RANGE_BLEU", "SUBNUM_RANGE_TER", "SUBNUM_RANGE_METEOR", "SUBNUM_RANGE_RATIO"]
        metric_values = parse_subnum_average(filepath)

    return metric_names, metric_values


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    # results[langpair][model_name][metric_name]

    results = defaultdict(lambda: defaultdict(lambda: defaultdict(str)))

    for root, langpairs, _ in walklevel(args.eval_folder, level=1):
        for langpair in langpairs:

            path_langpair = os.path.join(args.eval_folder, langpair)

            for subroot, model_names, _ in walklevel(path_langpair, level=1):
                for model_name in model_names:
                    path_model = os.path.join(path_langpair, model_name)

                    print("path_model: %s" % path_model)

                    for _, _, files in os.walk(path_model):
                        for file in files:
                            if file.endswith("subnum"):
                                continue
                            else:
                                corpus, decoding_method, metric = parse_filename(file)

                                filepath = os.path.join(path_model, file)
                                print("filepath: %s" % filepath)

                                metric_names, metric_values = parse_metric_values(metric, filepath)

                                for metric_name, metric_value in zip(metric_names, metric_values):
                                    results[langpair][model_name][metric_name] = metric_value

    print(results)


if __name__ == '__main__':
    main()
