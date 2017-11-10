

LEXICON=$1
INFILE=$2
OUTFILE=$3


DIR=/vol/bigdata2/datasets2/TraMOOC/Tools/Lemmatizers/lemmagen/v2/lemmagen/binary/linux

cd $DIR

./lemmatize --langmode b --lang $LEXICON $INFILE $OUTFILE
  
