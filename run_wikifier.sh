#!/bin/sh

#runs on scootaloo only

DIR=/vol/customopt/nlptools/wiki2//Wikifier2013/

cd $DIR

#. pathadd nlptools

OUTDIR=$1
FILENAME=$2
#MYCONFIG=$3   #vol/customopt/nlptools/wiki2//Wikifier2013/configs/STAND_ALONE_GUROBI.xml

/vol/customopt/java8/bin/java -Xmx50G -jar /vol/customopt/nlptools/wiki2/Wikifier2013/dist/wikifier-3.0-jar-with-dependencies.jar  -annotateData $OUTDIR/$FILENAME $OUTDIR false /vol/customopt/nlptools/wiki2/Wikifier2013/configs/FULL.xml
