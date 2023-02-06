#!/bin/bash

# Usage: ./maus-general.sh audio.{ogg,wav,mp4} transcript.{txt,par} {cs,en,de} > timestamps.auda.txt

# It runs WebMAUS forced aligner (through API call on the server) to assign word-level timestamps.

audio=$1

LANG=deu-DE
if [ -z "$3" ]; then
	echo default language is $LANG >&2
else
	if [ "$3" == cs ]; then
		LANG=sampa
	else if [ "$3" == en ]; then
		LANG=eng
	else if [ "$3" == de ]; then
		LANG=deu-DE
	else
		LANG=$3
		echo Language is $LANG, ok?
	fi; fi; fi
fi

par=$2

tdir=$(mktemp -d)

mkdir -p $tdir

if [[ "$par" != *.par ]]; then
	input=$tdir/input.par
	./g2p.sh $2 $3 > $input
	par=$input
fi


out=$tdir/out1.html

curl -v -X POST -H 'content-type: multipart/form-data' -F SIGNAL=@$audio -F LANGUAGE=$LANG -F MODUS=standard -F INSKANTEXTGRID=true -F RELAXMINDUR=false -F OUTFORMAT=TextGrid -F TARGETRATE=100000 -F ENDWORD=999999 -F RELAXMINDURTHREE=false -F STARTWORD=0 -F INSYMBOL=sampa -F PRESEG=true -F USETRN=false -F BPF=@$par -F MAUSSHIFT=default -F INSPROB=0.0 -F INSORTTEXTGRID=true -F OUTSYMBOL=sampa -F MINPAUSLEN=5 -F WEIGHT=default -F NOINITIALFINALSILENCE=false -F ADDSEGPROB=false 'https://clarin.phonetik.uni-muenchen.de/BASWebServices/services/runMAUS' > $out

LINK=$(sed 's/.*<downloadLink>//;s@</download.*@@' $out)

outgrid=$tdir/out.TextGrid
curl $LINK > $outgrid

if python3 tgrid_to_aud.py $outgrid ; then
	rm -rf $tdir
else
	echo ERROR: There was an erorr. You can inspect the partial outputs in tempdir >&2
	echo $tdir >&2
fi
