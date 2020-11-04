#! /usr/bin/python3

import argparse
import logging
import pycountry
import sacrebleu

from typing import Union


WMT_KEYS = ["wmt%02d" % year for year in range(8, 21)]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--src-lang", type=str, help="Source language (ISO 639-2).", required=True)
    parser.add_argument("--trg-lang", type=str, help="Target language (ISO 639-2).", required=True)
    parser.add_argument("--echo", action="store_true", help="Echo the test set to STDOUT if there is a match.", required=False)

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

    return lang_object.alpha_3


def find_most_recent_key(src_query_lang: str, trg_query_lang: str) -> Union[str, None]:
    """

    :param src_query_lang:
    :param trg_query_lang:
    :return:
    """

    newest_match = None

    for wmt_key in WMT_KEYS:
        for dataset in sacrebleu.dataset.DATASETS[wmt_key]:
            for langpair_key in dataset.keys():
                if "-" in langpair_key:
                    src_lang, trg_lang = langpair_key.split("-")

                    if src_lang == src_query_lang and trg_lang == trg_query_lang:
                        newest_match = wmt_key

    return newest_match


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    src_query_lang_alpha_2 = convert_alpha3_to_alpha2(args.src_lang)
    trg_query_lang_alpha_2 = convert_alpha3_to_alpha2(args.trg_lang)

    most_recent_key = find_most_recent_key(src_query_lang=src_query_lang_alpha_2, trg_query_lang=trg_query_lang_alpha_2)

    langpair = "-".join([src_query_lang_alpha_2, trg_query_lang_alpha_2])

    all_codes = [args.src_lang, src_query_lang_alpha_2, args.trg_lang, trg_query_lang_alpha_2]

    logging.debug("Most recent WMT testset: %s" % most_recent_key)
    logging.debug("Language codes")
    logging.debug(str(all_codes))

    if args.echo:
        if most_recent_key is None:
            logging.warning("No testset available, call to sacrebleu will fail.")
        sacrebleu.utils.print_test_set(test_set=most_recent_key, langpair=langpair, side="both", origlang=None,
                                       subset=None)
    else:
        if most_recent_key is None:
            print("false")
        else:
            print("true")


if __name__ == '__main__':
    main()
