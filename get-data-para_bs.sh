# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e

N_THREADS=8

pair=$1  # input language pair

# data paths
MAIN_PATH=$PWD
PARA_PATH=$PWD/data/para
PROCESSED_PATH=$PWD/data/processed/XLM15
CODES_PATH=$MAIN_PATH/data/processed/nl-ul/codes #$MAIN_PATH/data/processed/nl-ul/codes
VOCAB_PATH=$MAIN_PATH/data/processed/nl-ul/vocab.nl-ul

TOOLS_PATH=$PWD/tools
MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl

SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $SRC -no-escape -threads $N_THREADS"
TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $TGT -no-escape -threads $N_THREADS"

# tools paths
TOOLS_PATH=$PWD/tools
TOKENIZE=$TOOLS_PATH/tokenize.sh
LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py
FASTBPE=$TOOLS_PATH/fastBPE/fast

# install tools
./install-tools.sh

# create directories
mkdir -p $PARA_PATH
mkdir -p $PROCESSED_PATH

# tokenize
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  for split in all train valid test; do
    if ! [[ -f "$PARA_PATH/$split.$pair.$lg.tok" ]]; then
      eval "cat $PARA_PATH/$split.$pair.$lg | $SRC_PREPROCESSING > $PARA_PATH/$split.$pair.$lg.tok"
    fi
  done
done


# apply BPE codes and binarize the parallel corpora
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  for split in train valid test; do
    $FASTBPE applybpe $PROCESSED_PATH/$split.$pair.$lg $PARA_PATH/$split.$pair.$lg.tok $CODES_PATH $VOCAB_PATH
    python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$split.$pair.$lg
  done
done
