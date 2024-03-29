#! /usr/bin/python3

import os
import argparse
import threading
import logging
import numpy

from subprocess import Popen, PIPE
from typing import List

from sacrebleu.tokenizers.tokenizer_13a import Tokenizer13a

# alternative:
# METEOR_DEFAULT_PATH = "/srv/scratch1/mmueller/fairseq-para/tools/meteor"

METEOR_DEFAULT_PATH = "/net/cephfs/scratch/mathmu/map-volatility/tools/meteor"


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--hyp", type=str, help="System hypotheses.", required=True)
    parser.add_argument("--ref", type=str, help="Reference translations.", required=True)
    parser.add_argument("--meteor-path", type=str, help="Folder with METEOR jar file.", required=False,
                        default=METEOR_DEFAULT_PATH)

    args = parser.parse_args()

    return args


class ExternalProcessor(object):
    """
    Thread-safe wrapper for interaction with an external I/O shell script

    Taken from:
    https://github.com/ZurichNLP/mtrain/blob/moses-only/mtrain/preprocessing/external.py
    """

    def __init__(self, command, stream_stderr=False, quiet: bool = False):
        """
        @param command the command that should be executed on the shell
        @param stream_stderr whether STDERR should be streamread in a non-
            blocking way
        """

        self.command = command
        self._stream_stderr = stream_stderr

        if not quiet:
            logging.debug("Executing %s", self.command)

        env = os.environ.copy()
        env['LC_ALL'] = "C"

        self._process = Popen(
            self.command,
            shell=True,
            env=env,
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE
        )
        self._lock = threading.Lock()

    def close(self):
        """
        Closes the underlying shell script (process).
        """
        self._process.terminate()

    def process(self, line):
        """
        Processes a line of input through the underlying shell script (process)
        and returns the corresponding output.
        """
        line = line.strip() + "\n"
        line = line.encode('utf-8')

        with self._lock:
            self._process.stdin.write(line)
            self._process.stdin.flush()
            result = self._process.stdout.readline()

        return result.decode('utf-8').strip()

    def read_error(self):
        """
        Attempts to read from STDERR.
        """

        with self._lock:
            error_lines = self._process.stderr.readlines()

        return [e.decode().strip() for e in error_lines]


class MeteorResult:

    def __init__(self,
                 score: float):
        self.score = score


class MeteorScorer(object):

    def __init__(self,
                 meteor_path: str = METEOR_DEFAULT_PATH,
                 quiet: bool = True,
                 meteor_alpha: float = 0.85) -> None:
        """

        """

        parameters = "%f 0.2 0.6 0.75" % meteor_alpha

        arguments = [
            'java -Xmx2G -jar %s/meteor-*.jar' % meteor_path,
            '-',  # blank refs
            '-',  # blank hyps
            '-stdio',  # standard I/O
            '-l other',  # do not assume supported language
            '-p "%s"' % parameters # configurable preference for recall or precision
        ]

        self.processor = ExternalProcessor(
            command=" ".join(arguments),
            stream_stderr=True,
            quiet=quiet
        )

        # sacrebleu tokenizer
        self.tokenizer = Tokenizer13a()

    def close(self):
        self.processor.close()
        del self.processor

    def score(self, hyp: str, ref: str) -> float:
        """
        Scores a single segment.

        Assumes that hyp and ref are NOT empty strings, does not
        check for performance reasons.
        """
        hyp = hyp.strip()
        ref = ref.strip()

        hyp = self.tokenizer(hyp)
        ref = self.tokenizer(ref)

        first_call_args = ["SCORE",
                           ref,
                           hyp]

        first_call_input = " ||| ".join(first_call_args)

        stats = self.processor.process(first_call_input)

        second_call_input = "EVAL ||| " + stats

        score = self.processor.process(second_call_input)

        try:
            score = float(score)
        except ValueError:
            error_lines = self.processor.read_error()
            logging.error("METEOR error for the following inputs:")
            logging.error(first_call_input)
            logging.error(second_call_input)
            for e in error_lines:
                logging.error(e)
            raise

        return score

    def sentence_score(self, hyp: str, refs: List[str]) -> MeteorResult:
        """
        Wrap score method for MBR decoding, same interface as sacrebleu methods.

        :param hyp:
        :param refs:
        :return:
        """
        ref = refs[0]
        return MeteorResult(self.score(hyp, ref))


def sentence_meteor(hyp: str, ref: str) -> float:
    """
    Stateless, single sentence pair

    Assumes METEOR default path, and overhead for object creation for each call.

    :param hyp:
    :param ref:
    :return:
    """
    ms = MeteorScorer(quiet=True)
    score = ms.score(hyp, ref)
    ms.close()

    return score


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    hyp_handle = open(args.hyp, "r")
    ref_handle = open(args.ref, "r")

    ms = MeteorScorer(args.meteor_path)

    scores = []

    for hyp, ref in zip(hyp_handle, ref_handle):

        score = ms.score(hyp, ref)
        scores.append(score)

    assert len(scores) > 0, "No scores computed. Are hyp or ref input files empty?"

    final_score = numpy.mean(scores)

    print(final_score)


if __name__ == '__main__':
    main()
