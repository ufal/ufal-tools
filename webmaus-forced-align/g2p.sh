#!/bin/bash

## Jak opravit BAS Czech G2P, aby to bral MAUS General

# -> exportovat jako sampa, myslím

# -> a pak

#sed -i 's/Ill=/Il=/' *.par
#sed -i 's/all=/al=/' *.par
#sed -i 's/ua:/uaa:/' *.par
#sed -i 's/ju:/juu:/g' *.par
#sed -i 's/ja:/jaa:/g' *.par
#sed 's/r_o_0/r_0/g;s/r_o/r_0/g' *.par

FILE=$1

if [ -z "$FILE" ]; then
	echo "USAGE: $0 filename language > output.par" >&2
	exit 1
fi

is_cs=false

LANG=deu-DE
if [ -z "$2" ]; then
	echo default language is $LANG >&2
else
	if [ "$2" == cs ]; then
		LANG=cze-CZ
		is_cs=true  # Czech will be postprocessed
	else if [ "$2" == en ]; then
		LANG=eng
	else if [ "$2" == de ]; then
		LANG=deu-DE
	else
		LANG=$2
		echo Language is $LANG, ok?
	fi; fi; fi
fi

echo "lang is $LANG" >&2


tdir=$(mktemp -d)


out=$tdir/g2P-out.html
curl -v -X POST -H 'content-type: multipart/form-data' -F com=no -F tgrate=16000 -F stress=no -F lng=$LANG -F lowercase=yes -F syl=no -F outsym=x-sampa -F nrm=yes -F i=@$FILE -F tgitem=ort -F align=no -F featset=standard -F iform=txt -F embed=no -F oform=bpf 'https://clarin.phonetik.uni-muenchen.de/BASWebServices/services/runG2P' > $out

LINK=$(sed 's/.*<downloadLink>//;s@</download.*@@' $out)

outpar=$tdir/out.par
curl $LINK > $outpar

cspar=$tdir/cs-out.par

if [ "$is_cs" == true ]; then
	echo tady >&2
	sed 's/Ill=/Il=/' $outpar > $cspar
	sed -i 's/all=/al=/' $cspar
	sed -i 's/ua:/uaa:/' $cspar
	sed -i 's/ju:/juu:/g' $cspar
	sed -i 's/ja:/jaa:/g' $cspar
	sed -i 's/ll=/l=/g' $cspar
	sed 's/r_o_0/r_0/g;s/r_o/r_0/g' $cspar
else
	cat $outpar
fi

rm -rf $tdir

