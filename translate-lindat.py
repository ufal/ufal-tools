#!/usr/bin/env python3

# Credits for this script goes to Ondra Dušek
# Dominik updated it.

from argparse import ArgumentParser
import requests  # pip install requests
import logging
import sys

logger = logging.getLogger(__name__)
handler = logging.StreamHandler(sys.stderr)
handler.setFormatter(logging.Formatter('%(asctime)-15s %(levelname)-8s %(message)s'))
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# specify the target here
TARGET="cs"
#TARGET="hi"
#TARGET="fr"

# Russian doesn't work from some reason...  
# TARGET="ru"

def process_file(in_file, out_file):
    transls = []
    fh = open(out_file, 'w', encoding='UTF-8')
    with open(in_file,"r") as in_f:
        texts=[]
        for line_no, text in enumerate(in_f):
            texts.append(text[:-1])
            if line_no > 0 and line_no % 10 == 0:
                print((texts,))
                r = requests.post('https://lindat.mff.cuni.cz/services/translation/api/v2/models/en-%s?tgt=%s&src=en' % (TARGET, TARGET), headers = {"accept": "application/json"}, data={'input_text': "\n".join(texts)})
                if r.status_code == 200:
                    transl = "".join([s+(" " if s[-1] != "\n" else "") for s in r.json()]) #"  ".join([sent.strip() for sent in r.json()])
                    logger.info('OK: %s\n  -> %s' % (text, transl))
                else:
                    logger.warn('!!Translation status code: %d' % r.status_code)
                    transls.append('%s' % r.status_code)

                logger.info("Line %d -- saving" % line_no)
                # save partial work every 100 requests
                fh.write("".join(transl))
                fh.flush()
                texts = []
    fh.close()




if __name__ == '__main__':
    ap = ArgumentParser()
    ap.add_argument('in_file', type=str, help='File to translate')
    ap.add_argument('out_file', type=str, help='Translated output')
    args = ap.parse_args()

    process_file(args.in_file, args.out_file)

