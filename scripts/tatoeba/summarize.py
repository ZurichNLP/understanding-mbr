#! /usr/bin/python3

import os
import argparse
import logging
import itertools
import operator

from typing import List, Tuple


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


def parse_beam_top(parts: List[str]):
    """
    Example: dev.beam.top.bleu

    :param parts:
    :return:
    """
    corpus, sample_origin, decoding_method, metric = parts

    seed = "-"
    num_samples = "10"

    return corpus, decoding_method, sample_origin, num_samples, seed, metric


def parse_sample_top(parts: List[str]):
    """
    Example: test.sample.top.2.meteor

    :param parts:
    :return:
    """
    corpus, sample_origin, decoding_method, seed, metric = parts

    num_samples = "1"

    return corpus, decoding_method, sample_origin, num_samples, seed, metric


def parse_mbr_beam(parts: List[str]):
    """
    Example: dev.mbr.beam.10.meteor

    :param parts:
    :return:
    """
    corpus, decoding_method, sample_origin, num_samples, metric = parts

    seed = "-"

    return corpus, decoding_method, sample_origin, num_samples, seed, metric


def parse_mbr_sample(parts: List[str]):
    """
    Example: dev.mbr.sample.15.2.meteor

    :param parts:
    :return:
    """
    corpus, decoding_method, sample_origin, num_samples, seed, metric = parts

    return corpus, decoding_method, sample_origin, num_samples, seed, metric


def parse_filename(filename: str):
    """

    :param filename:
    :return:
    """
    if filename.endswith("average"):
        filename = filename.replace("subnum.average", "subnum")

    parts = filename.split(".")

    if "top" in parts:
        if "beam" in parts:
            return parse_beam_top(parts)
        else:
            return parse_sample_top(parts)
    elif "mbr" in parts:
        if "beam" in parts:
            return parse_mbr_beam(parts)
        else:
            return parse_mbr_sample(parts)

    else:
        logging.error("Cannot parse filename: '%s'" % filename)


def read_bleu(filename: str) -> str:

    with open(filename, "r") as infile:
        line = infile.readline().strip()

        parts = line.split(" ")

    if len(parts) < 3:
        return "-"

    return parts[2]


def read_meteor(filename: str) -> str:

    with open(filename, "r") as infile:
        line = infile.readline().strip()

    if line == "":
        return "-"

    return format(float(line), '.3f')


def read_subnum_average(filename: str):

    with open(filename, "r") as infile:
        lines = infile.readlines()
        lines = [l.strip() for l in lines]

    parts = lines[-1].split("\t")

    parts = [format(float(p), '.3f') for p in parts]

    bleu, ter, meteor, ratio = parts

    return bleu, ter, meteor, ratio


def read_metric_values(metric, filepath):

    if metric == "bleu":
        metric_names = ["BLEU"]
        metric_values = [read_bleu(filepath)]
    elif metric == "meteor":
        metric_names = ["METEOR"]
        metric_values = [read_meteor(filepath)]
    else:
        metric_names = ["SUBNUM_RANGE_BLEU", "SUBNUM_RANGE_TER", "SUBNUM_RANGE_METEOR", "SUBNUM_RANGE_RATIO"]
        metric_values = read_subnum_average(filepath)

    return metric_names, metric_values


class Result(object):

    def __init__(self,
                 langpair,
                 model_name,
                 corpus,
                 decoding_method,
                 sample_origin,
                 num_samples,
                 seed,
                 metric_names,
                 metric_values):

        self.langpair = langpair
        self.model_name = model_name
        self.corpus = corpus
        self.decoding_method = decoding_method
        self.sample_origin = sample_origin
        self.num_samples = num_samples
        self.seed = seed
        self.metric_dict = {}

        self.update_metrics(metric_names, metric_values)

    def update_metrics(self,
                       metric_names,
                       metric_values):

        for name, value in zip(metric_names, metric_values):
            self.update_metric(name, value)

    def update_metric(self, metric_name, metric_value):
        assert metric_name not in self.metric_dict.keys(), "Refusing to overwrite existing metric key!"
        self.metric_dict[metric_name] = metric_value

    def __repr__(self):
        metric_dict = str(self.metric_dict)

        return "+".join([self.langpair,
                         self.model_name,
                         self.corpus,
                         self.decoding_method,
                         self.sample_origin,
                         self.num_samples,
                         self.seed,
                         metric_dict])

    def signature(self) -> str:

        return "+".join([self.langpair,
                         self.model_name,
                         self.corpus,
                         self.decoding_method,
                         self.sample_origin,
                         self.num_samples,
                         self.seed])


def collapse_metrics(results: List[Result]) -> Result:
    """

    :param results:
    :return:
    """
    first_result = results[0]

    for r in results[1:]:
        for name, value in r.metric_dict.values():
            first_result.update_metric(name, value)

    return first_result


def reduce_results(results: List[Result]) -> List[Result]:
    """

    :param results:
    :return:
    """

    with_signatures = [(r.signature(), r) for r in results]  # type: List[Tuple[str, Result]]
    with_signatures.sort(key=operator.itemgetter(0))

    by_signature_iterator = itertools.groupby(with_signatures, operator.itemgetter(0))

    reduced_results = []

    for signature, subiterator in by_signature_iterator:
        subresults = [r for s, r in subiterator]
        reduced_result = collapse_metrics(subresults)
        reduced_results.append(reduced_result)

    return reduced_results


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    results = []

    for root, langpairs, _ in walklevel(args.eval_folder, level=1):

        print(langpairs)

        for langpair in langpairs:

            path_langpair = os.path.join(args.eval_folder, langpair)

            model_names = ['baseline', 'no_label_smoothing']

            for model_name in model_names:
                path_model = os.path.join(path_langpair, model_name)

                for _, _, files in os.walk(path_model):
                    for file in files:
                        if file.endswith("subnum"):
                            # exclude this file
                            continue
                        else:
                            corpus, decoding_method, sample_origin, num_samples, seed, metric = parse_filename(file)

                            filepath = os.path.join(path_model, file)

                            metric_names, metric_values = read_metric_values(metric, filepath)

                            result = Result(langpair,
                                            model_name,
                                            corpus,
                                            decoding_method,
                                            sample_origin,
                                            num_samples,
                                            seed,
                                            metric_names,
                                            metric_values)

                            results.append(result)

    results = reduce_results(results)

    header_names = ["LANGPAIR",
                    "MODEL_NAME",
                    "CORPUS",
                    "DECODING_METHOD",
                    "SAMPLE_ORIGIN",
                    "NUM_SAMPLES",
                    "SEED",
                    "BLEU",
                    "METEOR",
                    "SUBNUM_RANGE_BLEU",
                    "SUBNUM_RANGE_TER",
                    "SUBNUM_RANGE_METEOR",
                    "SUBNUM_RANGE_RATIO"]

    metric_names = ["BLEU",
                    "METEOR",
                    "SUBNUM_RANGE_BLEU",
                    "SUBNUM_RANGE_TER",
                    "SUBNUM_RANGE_METEOR",
                    "SUBNUM_RANGE_RATIO"]

    print("\t".join(header_names))

    for r in results:
        values = [r.langpair, r.model_name, r.corpus, r.decoding_method, r.sample_origin, r.num_samples, r.seed]
        metrics = [r.metric_dict.get(m, "-") for m in metric_names]

        print("\t".join(values + metrics))


if __name__ == '__main__':
    main()
