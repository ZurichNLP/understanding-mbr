#! /usr/bin/python3

import math
import argparse
import logging


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--parts", type=int, help="How many parts.", required=True)
    parser.add_argument("--input", type=str, help="Input file.", required=True)

    args = parser.parse_args()

    return args


def chunks(lst, chunk_size: int):
    """
    Yield successive n-sized chunks from lst.

    Source:
    https://stackoverflow.com/questions/312443/how-do-you-split-a-list-into-evenly-sized-chunks
    """
    for i in range(0, len(lst), chunk_size):
        yield lst[i:i + chunk_size]


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    input_handle = open(args.input, "r")
    input_lines = input_handle.readlines()

    len_input = len(input_lines)

    chunk_size = math.ceil(len_input / args.parts)

    for index, chunk in enumerate(chunks(input_lines, chunk_size)):

        file_name = args.input + "." + str(index + 1)

        with open(file_name, "w") as outfile:
            for line in chunk:
                outfile.write(line)


if __name__ == '__main__':
    main()
