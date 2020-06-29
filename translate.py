import torch

from fairseq.models.transformer import TransformerModel

def load_model():

    de2en = TransformerModel.from_pretrained(
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

def translate_file(inpath, outpath):

    inputs = [l.strip() for l in open(inpath, "r").readlines()]

    de2en = load_model()

    outputs = de2en.translate(inputs)

    with open(outpath, "w") as handle:
        for output in outputs:
            handle.write(output + "\n")

#translate_file("data/wmt19-ende-wmtp.ref", "wmt.p.hyps")
# translate_file("data/wmt19-en-de.trg", "wmt.hyps")

model = load_model()

# original WMT sentence

translate_string('Walisische Abgeordnete sorgen sich "wie Dödel auszusehen"', model=model)

# paraphrased by a human

translate_string("Abgeordnete walisischen Ursprungs machen sich Sorgen, „wie Idioten auszusehen“", model=model)
