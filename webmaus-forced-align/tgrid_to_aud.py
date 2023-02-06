#!/usr/bin/env python3
import sys
import textgrids as tg   ##  pip install praat-textgrids

fname = sys.argv[1]
grid = tg.TextGrid(fname)

for interval in grid["ORT-MAU"]:
    beg = interval.xmin
    end = interval.xmax
    text = interval.text
    if text:
        print(beg,end,text,sep="\t")

#events = []
#i = 1
#with open(FNAME+".txt","w") as f:
#    for sil in grid['silences']:
#        if sil.text == "silent":
#            events.append((sil.xmin, "sil-beg"))
#            events.append((sil.xmax, "sil-end"))
#        else:
#            print("%f\t%f\t%s" % (sil.xmin,sil.xmax,"sounding %d" % i),file=f)
#            i += 1
#
#for syll in grid['syllables']:
#    events.append((syll.xpos,"syll"))
#
#events = sorted(events, key=lambda x:x[0])
#while "sil" in events[0][1]:
#    events.pop(0)
#
#with open(FNAME+".bla","w") as f:
#    for t,ev in events:
#        if ev == "syll":
#            print("bla",end=" ",file=f)
#        elif ev == "sil-end":
#            print(".",file=f)
#
#~                                                                                                                                                                                                                 
#~                                                                                                                                                                                                                 
#~                                                                                                                                                                                                                 
#~                                                                                                                                                                                                                 
#~                                                   
