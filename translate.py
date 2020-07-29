import sys
import torch
import copy

from typing import List

from fairseq import hub_utils
from fairseq.models.transformer import TransformerModel

class GeneratorHubInterfaceWithScoring(hub_utils.GeneratorHubInterface):

    def translate_with_score(self, sentences: List[str], beam: int = 5, nbest_size: int = 1, verbose: bool = False, **kwargs) -> List[str]:
        return self.sample_with_score(sentences, beam, nbest_size, verbose, **kwargs)

    def sample_with_score(self, sentences: List[str], beam: int = 1, nbest_size: int = 1, verbose: bool = False, **kwargs) -> List[str]:

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

        x = hub_utils.from_pretrained(
            model_name_or_path,
            checkpoint_file,
            data_name_or_path,
            archive_map=cls.hub_models(),
            **kwargs,
        )

        return GeneratorHubInterfaceWithScoring(x['args'], x['task'], x['models'])


def load_model():

    de2en = TransformerModelWithScoring.from_pretrained(
      'model/wmt19.de-en.joined-dict.ensemble',
      checkpoint_file='model1.pt',
      bpe='fastbpe',
      tokenizer='moses',
      bpe_codes='model/wmt19.de-en.joined-dict.ensemble/bpecodes'
    )

    de2en.eval()

    de2en.cuda()

    return de2en

def translate_string(text, model=None):

    if model is None:
        model = load_model()
    print(model.translate(text))

def interactive():

    import readline

    model = load_model()

    while True:

        try:
            line = input("> ")

            if line.strip() != "":
                output = model.translate(line)
                print("  " + output)

        except KeyboardInterrupt:
            print()
            exit(0)

def translate_file(inpath, outpath):

    inputs = [l.strip() for l in open(inpath, "r").readlines()]

    de2en = load_model()

    outputs = de2en.translate(inputs)

    with open(outpath, "w") as handle:
        for output in outputs:
            handle.write(output + "\n")

def translate_stdin():

    inputs = [l.strip() for l in sys.stdin.readlines()]

    de2en = load_model()

    outputs = de2en.translate_with_score(inputs, nbest_size=3)

    for nbest_list in outputs:
        for index, hyp in enumerate(nbest_list):
            score, output = hyp
            score = str(score.cpu().detach().numpy())
            sys.stdout.write(str(index) + "\t" + score + "\t" + output + "\n")

#translate_file("data/wmt19-ende-wmtp.ref", "wmt.p.hyps")
# translate_file("data/wmt19-en-de.trg", "wmt.hyps")

#model = load_model()

# original WMT sentence

# translate_string('Walisische Abgeordnete sorgen sich "wie Dödel auszusehen"', model=model)

# paraphrased by a human

#translate_string("Abgeordnete walisischen Ursprungs machen sich Sorgen, „wie Idioten auszusehen“", model=model)

# interactive()

translate_stdin()
