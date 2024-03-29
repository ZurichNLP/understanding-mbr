#! /usr/bin/python3

import sys
import pickle
import argparse
import logging
import pycountry
import pycld2 as cld2

from collections import Counter


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--output", type=str, help="Where to save pickle of langid counter.", required=True)

    args = parser.parse_args()

    return args


def convert_alpha3_to_alpha2(alpha_3: str) -> str:
    """

    :param alpha_3:
    :return:
    """

    lang_object = pycountry.languages.get(alpha_3=alpha_3)

    return lang_object.alpha_2


def convert_alpha2_to_alpha3(alpha_2: str) -> str:
    """

    :param alpha_2:
    :return:
    """

    lang_object = pycountry.languages.get(alpha_2=alpha_2)

    # conversion sometimes fails because of language coverage, but also mismatch in lang codes such as this one;
    # jv != jw
    # pycountry object: Language(alpha_2='jv', alpha_3='jav', name='Javanese', scope='I', type='L')
    # cld2 detection output:
    # >>> cld2.detect("diuwbdw738732", bestEffort=True)
    # (True, 9, (('JAVANESE', 'jw', 88, 512.0), ('Unknown', 'un', 0, 0.0), ('Unknown', 'un', 0, 0.0)))

    if lang_object is None:
        return "UNKNOWN"

    return lang_object.alpha_3


def detect_language(line: str) -> str:
    """

    :param line:
    :return:
    """

    # Example output of this function:
    # >>> cld2.detect("Mein Onkel ist gelb.", bestEffort=True)
    # (True, 21, (('GERMAN', 'de', 95, 1024.0), ('Unknown', 'un', 0, 0.0), ('Unknown', 'un', 0, 0.0)))

    is_reliable, text_bytes_found, details = cld2.detect(line, bestEffort=True)

    language_alpha2 = details[0][1]

    return convert_alpha2_to_alpha3(language_alpha2)



def main():
    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    counter = Counter()

    for line in sys.stdin:
        line = line.strip()
        language = detect_language(line)
        counter.update([language])

    with open(args.output, "wb") as outfile:
        pickle.dump(counter, outfile)

if __name__ == '__main__':
    main()
