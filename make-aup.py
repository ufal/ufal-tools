#!/usr/bin/env python3

# Create audacity project file that opens audio and label tracks at once,
# without need to open them manually, which is quite slow.

# Usage:

# 1)
# python3 make-aup.py D_cs.mp3 D_cs.tt.txt R_mr.mp3 R_mr.tt.txt R_en.tt.txt > proj.aup

# 2)
## then you need to create an empty directory named proj where Audacity saves its temporary files, it crashes if it doesn't exist.

# mkdir -p proj

# 3)
# audacity proj.aup

# It will open audacity with loaded audio and label tracks in the order that 
# you specify as command line args of make-aup.py .

# (Credits: by Dominik, originally created for ESIC corpus in 2020 within ELITR project.) 
# (Then used for InCroMin and IWLST26.)

import sys
import os

"""<label t="914.3200000000" t1="992.2300000000" title="M_S149 Magor Imre Csibi"/>
<label t="914.3200000000" t1="998.7700000000" title="cze interpreter"/>
"""

header = """<?xml version="1.0" standalone="no" ?>
<!DOCTYPE project PUBLIC "-//audacityproject-1.3.0//DTD//EN" "http://audacity.sourceforge.net/xml/audacityproject-1.3.0.dtd" >
<project xmlns="http://audacity.sourceforge.net/xml/" projname="%s" version="1.3.0" audacityversion="2.4.2" sel0="0.0000000000" sel1="0.0000000000" vpos="0" h="%1.10f" zoom="75.1858999448" rate="44100.0" snapto="off" selectionformat="hh:mm:ss + milliseconds" frequencyformat="Hz" bandwidthformat="octaves">
	<tags>
		<tag name="major_brand" value="isom"/>
		<tag name="minor_version" value="512"/>
		<tag name="encoder" value="Lavc57.107.100 libvorbis"/>
		<tag name="handler_name" value="SoundHandler"/>
		<tag name="compatible_brands" value="isomiso2mp41"/>
		<tag name="language" value="cze"/>
	</tags>
"""


track_template = """<import filename="%s" offset="0.00000000" mute="0" solo="0" height="75" minimized="0" gain="1.0" pan="0.0"/>
"""

label_template = """<labeltrack name="%s" isSelected="0" height="116" minimized="0" numlabels="%d">
		%s	</labeltrack>
"""

footer = """</project>"""


from xml.sax.saxutils import escape
def exp(x):
	if not os.path.isfile(x):
		return 0,""
	out_a = []
	with open(x,"r") as f:
		for line in f:
			beg,end,label = line.split("\t")
			beg = float(beg)
			end = float(end)
			label = label.strip()
			out = '<label t="%1.10f" t1="%1.10f" title="%s"/>' % (beg,end,label.replace('"','&quot;'))
			out += "\n"
			out_a.append(out)
	return len(out_a),"\t\t".join(out_a)	

def get_beg(x):
	with open(x,"r") as f:
		for line in f:
			beg,end,label = line.split("\t")
			beg = float(beg)
			return beg
			
filled_template = header % ("proj",20)

for fn in sys.argv[1:]:
	if fn.endswith("mp3"):
		filled_template += track_template % fn 
	else:
		filled_template += label_template % (fn, *exp(fn))
filled_template += footer

print(filled_template)
