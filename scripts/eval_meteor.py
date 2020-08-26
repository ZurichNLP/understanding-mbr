#! /usr/bin/python3

import os
import argparse
import threading
import logging
import numpy

from subprocess import Popen, PIPE
from queue import Queue, Empty

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

        # avoid wrong LC_NUMERIC or similar?
        # https://github.com/Maluuba/nlg-eval/pull/33

        env = os.environ.copy()
        env['LC_ALL'] = "C"

        self._process = Popen(
            self.command,
            shell=True,
            env=env,
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE if self._stream_stderr else None
        )
        self._lock = threading.Lock()
        if self._stream_stderr:
            self._nbsr = _NonBlockingStreamReader(self._process.stderr)

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

            # attempt reading from STDERR
            if self._stream_stderr:
                errors = self._nbsr.readline()
                if errors:
                    message = errors.decode()
                    logging.info(message.strip())
        return result.decode().strip()


class _NonBlockingStreamReader:
    """
    Reads from stream without blocking, even if nothing can be read
    """

    def __init__(self, stream):
        """
        @param stream the stream to read from, usually a process' STDOUT or STDERR
        """

        self._stream = stream
        self._queue = Queue()

        def _populate_queue(__stream, queue):
            """
            Collects lines from '@param stream and puts them in @param queue.
            """

            while True:
                line = __stream.readline()
                if line:
                    queue.put(line)
                else:
                    raise _UnexpectedEndOfStream

        self._thread = threading.Thread(target=_populate_queue,
                                        args=(self._stream, self._queue))
        self._thread.daemon = True
        self._thread.start()  # start collecting lines from the stream

    def readline(self, timeout=None):
        try:
            return self._queue.get(block=timeout is not None,
                                   timeout=timeout)
        except Empty:
            return None


class _UnexpectedEndOfStream(Exception):
    pass


class MeteorScorer(object):

    def __init__(self, meteor_path: str = METEOR_DEFAULT_PATH, quiet: bool =True) -> None:
        """

        """
        arguments = [
            'java -Xmx2G -jar %s/meteor-*.jar' % meteor_path,
            '-',  # blank refs
            '-',  # blank hyps
            '-stdio',  # standard I/O
            '-l other',  # do not assume supported language
        ]

        self.processor = ExternalProcessor(
            command=" ".join(arguments),
            stream_stderr=True,
            quiet=quiet
        )

        # sacrebleu tokenizer
        self.tokenizer = Tokenizer13a()

    def close(self):
        del self.processor

    def score(self, hyp: str, ref: str) -> float:
        """
        Scores a single segment.
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

        return float(score)


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
