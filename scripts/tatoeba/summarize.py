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
    Structure:  $corpus.beam.$length_penalty_alpha.top.$beam_size.$metric
    Example:    dev.beam.1.0.top.5.bleu

    :param parts:
    :return:
    """
    corpus, sample_origin, length_penalty_alpha_a, length_penalty_alpha_b, decoding_method, num_samples, metric = parts

    length_penalty_alpha = ".".join([length_penalty_alpha_a, length_penalty_alpha_b])

    seed = "-"
    utility_function = "-"

    return corpus, decoding_method, sample_origin, num_samples, seed, length_penalty_alpha, utility_function, metric


def parse_sample_top(parts: List[str]):
    """
    Structure:  $corpus.sample.top.$seed.$metric
    Example:    test.sample.top.2.meteor

    :param parts:
    :return:
    """
    corpus, sample_origin, decoding_method, seed, metric = parts

    num_samples = "1"
    length_penalty_alpha = "-"
    utility_function = "-"

    return corpus, decoding_method, sample_origin, num_samples, seed, length_penalty_alpha, utility_function, metric


def parse_mbr_beam(parts: List[str]):
    """
    Structure:  $corpus.mbr.$utility_function.beam.$length_penalty_alpha.$num_samples.$metric
    Example:    dev.mbr.sentence-meteor.beam.1.0.10.meteor

    :param parts:
    :return:
    """
    corpus, decoding_method, utility_function, sample_origin, length_penalty_alpha_a, length_penalty_alpha_b, \
        num_samples, metric = parts

    length_penalty_alpha = ".".join([length_penalty_alpha_a, length_penalty_alpha_b])

    seed = "-"

    return corpus, decoding_method, sample_origin, num_samples, seed, length_penalty_alpha, utility_function, metric


def parse_mbr_sample(parts: List[str]):
    """
    Structure:  $corpus.mbr.$utility_function.sample.$num_samples.$seed.$metric
    Example:    dev.mbr.sentence-meteor.sample.15.2.meteor

    :param parts:
    :return:
    """
    corpus, decoding_method, utility_function, sample_origin, num_samples, seed, metric = parts

    length_penalty_alpha = "-"

    return corpus, decoding_method, sample_origin, num_samples, seed, length_penalty_alpha, utility_function, metric


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


def read_chrf(filename: str) -> str:
    """
    Example content: #chrF2+numchars.6+space.false+version.1.4.14 = 0.47

    :param filename:
    :return:
    """

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
    elif "chrf" in metric:
        metric_names = [metric.upper()]
        metric_values = [read_chrf(filepath)]
    elif metric == "chrf_balanced":
        metric_names = ["CHRF_BALANCED"]
        metric_values = [read_chrf(filepath)]
    elif metric == "meteor":
        metric_names = ["METEOR"]
        metric_values = [read_meteor(filepath)]
    elif metric == "meteor_balanced":
        metric_names = ["METEOR_BALANCED"]
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
                 utility_function,
                 length_penalty_alpha,
                 num_samples,
                 seed,
                 metric_names,
                 metric_values):

        self.langpair = langpair
        self.model_name = model_name
        self.corpus = corpus
        self.decoding_method = decoding_method
        self.sample_origin = sample_origin
        self.utility_function = utility_function
        self.length_penalty_alpha = length_penalty_alpha
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

        return "Result(%s)" % "+".join([self.langpair,
                                        self.model_name,
                                        self.corpus,
                                        self.decoding_method,
                                        self.sample_origin,
                                        self.utility_function,
                                        self.length_penalty_alpha,
                                        self.num_samples,
                                        self.seed,
                                        metric_dict])

    def signature(self) -> str:

        return "+".join([self.langpair,
                         self.model_name,
                         self.corpus,
                         self.decoding_method,
                         self.sample_origin,
                         self.utility_function,
                         self.length_penalty_alpha,
                         self.num_samples,
                         self.seed])


def collapse_metrics(results: List[Result]) -> Result:
    """

    :param results:
    :return:
    """
    first_result = results[0]

    for r in results[1:]:
        for name, value in r.metric_dict.items():
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


def get_model_names() -> List[str]:
    """

    :return:
    """
    model_names = ['baseline', 'no_label_smoothing', 'dry_run', 'slice_dev', 'slice_dev+optimize', 'domain_robustness']

    noise_probabilities = "0.001 0.005 0.01 0.05 0.075 0.1 0.25 0.5".split(" ")

    for noise_probability in noise_probabilities:
        model_names.append("copy_noise." + noise_probability)

    return model_names


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    results = []

    for root, langpairs, _ in walklevel(args.eval_folder, level=0):

        logging.debug("Language pairs:")
        logging.debug(langpairs)

        for langpair_index, langpair in enumerate(langpairs):

            path_langpair = os.path.join(args.eval_folder, langpair)

            model_names = get_model_names()

            if langpair_index == 0:
                logging.debug("Model names:")
                logging.debug(model_names)

            for model_name in model_names:
                path_model = os.path.join(path_langpair, model_name)

                for _, _, files in os.walk(path_model):
                    for file in files:
                        if file.endswith("subnum"):
                            # exclude this file
                            continue
                        else:
                            corpus, decoding_method, sample_origin, num_samples, seed, \
                                length_penalty_alpha, utility_function, metric = parse_filename(file)

                            filepath = os.path.join(path_model, file)

                            metric_names, metric_values = read_metric_values(metric, filepath)

                            result = Result(langpair,
                                            model_name,
                                            corpus,
                                            decoding_method,
                                            sample_origin,
                                            utility_function,
                                            length_penalty_alpha,
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
                    "UTILITY_FUNCTION",
                    "LENGTH_PENALTY_ALPHA",
                    "NUM_SAMPLES",
                    "SEED",
                    "BLEU",
                    "CHRF_1",
                    "CHRF_2",
                    "CHRF_3",
                    "METEOR",
                    "METEOR_BALANCED"]

    metric_names = ["BLEU",
                    "CHRF_1",
                    "CHRF_2",
                    "CHRF_3",
                    "METEOR",
                    "METEOR_BALANCED"]

    print("\t".join(header_names))

    for r in results:
        values = [r.langpair, r.model_name, r.corpus, r.decoding_method, r.sample_origin, r.utility_function,
                  r.length_penalty_alpha, r.num_samples, r.seed]
        metrics = [r.metric_dict.get(m, "-") for m in metric_names]

        print("\t".join(values + metrics))


if __name__ == '__main__':
    main()
