#! /usr/bin/python3

from methodtools import lru_cache
from collections import Counter
from sacrebleu import CHRF, BLEU, BLEUScore, CHRFScore
from itertools import zip_longest
from typing import List, Iterable, Union


# these values should be changed if MBR is performed with more or less than 100 samples

LRU_CACHE_SIZE_CHRF = 600
LRU_CACHE_SIZE_BLEU = 100


class CachedCHRF(CHRF):

    @lru_cache(maxsize=LRU_CACHE_SIZE_CHRF)
    def extract_char_ngrams(self, s: str, n: int) -> Counter:
        """
        Yields counts of character n-grams from string s of order n.
        """
        return Counter([s[i:i + n] for i in range(len(s) - n + 1)])

    def cache_info(self) -> str:
        return self.extract_char_ngrams.cache_info()

    def cache_clear(self) -> None:
        self.extract_char_ngrams.cache_clear()


class CachedPrecisionCHRF(CHRF):

    @lru_cache(maxsize=LRU_CACHE_SIZE_CHRF)
    def extract_char_ngrams(self, s: str, n: int) -> Counter:
        """
        Yields counts of character n-grams from string s of order n.
        """
        return Counter([s[i:i + n] for i in range(len(s) - n + 1)])

    def cache_info(self) -> str:
        return self.extract_char_ngrams.cache_info()

    def cache_clear(self) -> None:
        self.extract_char_ngrams.cache_clear()

    def sentence_score(self, hypothesis: str, references: List[str]) -> CHRFScore:
        """
        Computes ChrF on a single sentence pair.
        :param hypothesis: Hypothesis string.
        :param references: Reference string(s).
        :return: Chrf score.
        """
        hypothesis, references = references[0], [hypothesis]

        assert not isinstance(references, str), \
            "sentence_score needs a list of references, not a single string"
        stats = self.get_sentence_statistics(hypothesis, references)
        return self.compute_chrf(stats, self.order, self.beta)


class CachedBLEU(BLEU):

    @lru_cache(maxsize=LRU_CACHE_SIZE_BLEU)
    @staticmethod
    def extract_ngrams(line, min_order=1, max_order=BLEU.NGRAM_ORDER) -> Counter:
        """Extracts all the ngrams (min_order <= n <= max_order) from a sequence of tokens.
        :param line: A segment containing a sequence of words.
        :param min_order: Minimum n-gram length (default: 1).
        :param max_order: Maximum n-gram length (default: NGRAM_ORDER).
        :return: a dictionary containing ngrams and counts
        """

        ngrams = Counter()  # type: Counter
        tokens = line.split()
        for n in range(min_order, max_order + 1):
            for i in range(0, len(tokens) - n + 1):
                ngram = ' '.join(tokens[i: i + n])
                ngrams[ngram] += 1

        return ngrams

    @staticmethod
    def reference_stats(refs, output_len):
        """Extracts reference statistics for a given segment.
        :param refs: A list of segment tokens.
        :param output_len: Hypothesis length for this segment.
        :return: a tuple of (ngrams, closest_diff, closest_len)
        """

        ngrams = Counter()
        closest_diff = None
        closest_len = None

        for ref in refs:
            tokens = ref.split()
            reflen = len(tokens)
            diff = abs(output_len - reflen)
            if closest_diff is None or diff < closest_diff:
                closest_diff = diff
                closest_len = reflen
            elif diff == closest_diff:
                if reflen < closest_len:
                    closest_len = reflen

            ngrams_ref = CachedBLEU.extract_ngrams(ref)
            for ngram in ngrams_ref.keys():
                ngrams[ngram] = max(ngrams[ngram], ngrams_ref[ngram])

        return ngrams, closest_diff, closest_len

    def corpus_score(self, sys_stream: Union[str, Iterable[str]],
                     ref_streams: Union[str, List[Iterable[str]]],
                     use_effective_order: bool = False) -> BLEUScore:
        """Produces BLEU scores along with its sufficient statistics from a source against one or more references.
        :param sys_stream: The system stream (a sequence of segments)
        :param ref_streams: A list of one or more reference streams (each a sequence of segments)
        :param use_effective_order: Account for references that are shorter than the largest n-gram.
        :return: a `BLEUScore` object containing everything you'd want
        """

        # Add some robustness to the input arguments
        if isinstance(sys_stream, str):
            sys_stream = [sys_stream]

        if isinstance(ref_streams, str):
            ref_streams = [[ref_streams]]

        sys_len = 0
        ref_len = 0

        correct = [0 for n in range(self.NGRAM_ORDER)]
        total = [0 for n in range(self.NGRAM_ORDER)]

        # look for already-tokenized sentences
        tokenized_count = 0

        fhs = [sys_stream] + ref_streams
        for lines in zip_longest(*fhs):
            if None in lines:
                raise EOFError("Source and reference streams have different lengths!")

            if self.lc:
                lines = [x.lower() for x in lines]

            if not (self.force or self.tokenizer.signature() == 'none') and lines[0].rstrip().endswith(' .'):
                tokenized_count += 1

            output, *refs = [self.tokenizer(x.rstrip()) for x in lines]

            output_len = len(output.split())
            ref_ngrams, closest_diff, closest_len = CachedBLEU.reference_stats(refs, output_len)

            sys_len += output_len
            ref_len += closest_len

            sys_ngrams = CachedBLEU.extract_ngrams(output)
            for ngram in sys_ngrams.keys():
                n = len(ngram.split())
                correct[n - 1] += min(sys_ngrams[ngram], ref_ngrams.get(ngram, 0))
                total[n - 1] += sys_ngrams[ngram]

        # Get BLEUScore object
        score = self.compute_bleu(
            correct, total, sys_len, ref_len,
            smooth_method=self.smooth_method, smooth_value=self.smooth_value,
            use_effective_order=use_effective_order)

        return score

    def cache_info(self) -> str:
        return CachedBLEU.extract_ngrams.cache_info()

    def cache_clear(self) -> None:
        CachedBLEU.extract_ngrams.cache_clear()
