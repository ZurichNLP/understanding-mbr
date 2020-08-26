#! /usr/bin/python3

import os
import argparse
import logging


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


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    for root, langpairs, _ in walklevel(args.eval_folder, level=1):
        for langpair in langpairs:

            path_langpair = os.path.join(root, langpair)

            for root, model_names, _ in walklevel(path_langpair, level=1):
                for model_name in model_names:
                    path_model = os.path.join(path_langpair, model_name)

                    for _, _, files in os.walk(path_model):






if __name__ == '__main__':
    main()
