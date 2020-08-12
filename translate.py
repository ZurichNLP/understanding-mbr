import sys
import torch
import logging
import argparse

from typing import List

import numpy as np

from fairseq import hub_utils, utils
from fairseq.models.transformer import TransformerModel


class GeneratorHubInterfaceWithScoring(hub_utils.GeneratorHubInterface):

    def translate_with_score(self, sentences: List[str], beam: int = 5, nbest_size: int = 1, verbose: bool = False, **kwargs) -> List[str]:
        """

        :param sentences:
        :param beam:
        :param nbest_size:
        :param verbose:
        :param kwargs:
        :return:
        """
        return self.sample_with_score(sentences, beam, nbest_size, verbose, **kwargs)

    def sample_with_score(self, sentences: List[str], beam: int = 1, nbest_size: int = 1, verbose: bool = False, **kwargs) -> List[str]:
        """

        :param sentences:
        :param beam:
        :param nbest_size:
        :param verbose:
        :param kwargs:
        :return:
        """

        if isinstance(sentences, str):
            return self.sample_with_score([sentences], beam=beam, nbest_size=nbest_size, verbose=verbose, **kwargs)[0]
        tokenized_sentences = [self.encode(sentence) for sentence in sentences]
        batched_hypos = self.generate(tokenized_sentences, beam, verbose, **kwargs)

        results = []
        for hypos in batched_hypos:
            relevant_hyps = hypos[:nbest_size]
            relevant_hyps = [(hyp['score'], self.decode(hyp['tokens'])) for hyp in relevant_hyps]
            results.append(relevant_hyps)

        return results


class TransformerModelWithScoring(TransformerModel):

    @classmethod
    def from_pretrained(cls, model_name_or_path, checkpoint_file='model.pt', data_name_or_path='.', **kwargs):
        """

        :param model_name_or_path:
        :param checkpoint_file:
        :param data_name_or_path:
        :param kwargs:
        :return:
        """

        x = hub_utils.from_pretrained(
            model_name_or_path,
            checkpoint_file,
            data_name_or_path,
            archive_map=cls.hub_models(),
            **kwargs,
        )

        return GeneratorHubInterfaceWithScoring(x['args'], x['task'], x['models'])


def load_model(model_path: str,
               checkpoint_file: str,
               bpe_codes: str,
               bpe: str = "fastbpe",
               tokenizer: str = "moses") -> GeneratorHubInterfaceWithScoring:
    """

    :param model_path:
    :param checkpoint_file:
    :param bpe_codes:
    :param bpe:
    :param tokenizer:
    :return:
    """

    de2en = TransformerModelWithScoring.from_pretrained(
      model_path,
      checkpoint_file=checkpoint_file,
      bpe=bpe,
      tokenizer=tokenizer,
      bpe_codes=bpe_codes
    )

    de2en.eval()

    de2en.cuda()

    return de2en


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--method", type=str, help="Beam or sampling", required=True, choices=["beam", "sampling"])

    parser.add_argument("--beam_size", type=int, help="Size of nbest list (beam search) or number of samples (sampling)", required=False, default=5)
    parser.add_argument("--nbest_size", type=int, help="Size of nbest list (beam search) or number of samples (sampling)", required=True)

    parser.add_argument("--model-folder", type=str, help="Path to model folder", required=True)
    parser.add_argument("--checkpoint", type=str, help="Name of checkpoint file", required=True)
    parser.add_argument("--bpe-codes", type=str, help="Path to BPE model", required=True)

    parser.add_argument("--bpe-method", type=str, help="How to segment sentences into subwords", required=True)
    parser.add_argument("--tokenizer-method", type=str, help="How to tokenize sentences", required=True)

    parser.add_argument("--seed", type=int, help="RNG seed only relevant for sampling", required=False, default=None)

    args = parser.parse_args()

    return args


def main():

    args = parse_args()

    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)

    if args.seed is not None:
        np.random.seed(args.seed)
        utils.set_torch_seed(args.seed)

    model = load_model(model_path=args.model_folder,
                       checkpoint_file=args.checkpoint,
                       bpe_codes=args.bpe_codes,
                       bpe=args.bpe_method,
                       tokenizer=args.tokenizer_method)

    inputs = [l.strip() for l in sys.stdin.readlines()]

    outputs = model.translate_with_score(inputs,
                                         beam=args.beam_size,
                                         nbest_size=args.nbest_size,
                                         sampling=True if args.method == "sampling" else False)

    for nbest_list in outputs:
        for index, hyp in enumerate(nbest_list):
            score, output = hyp
            score = str(score.cpu().detach().numpy())
            sys.stdout.write(str(index) + "\t" + score + "\t" + output + "\n")


if __name__ == "__main__":
    main()
