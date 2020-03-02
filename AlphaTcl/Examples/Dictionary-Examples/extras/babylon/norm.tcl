# -*-tcl-*- nowrap

# This code is to be inserted in the beginning 
# of a babylon dictionary file

<!-- BEGIN TCL
	
# This proc takes the first word of the input string
# strips all accents,
# and then removes all non-alpha letters
proc normalForm { chunk } {
  regexp {^<hw>([^<]+)</hw>} $chunk dummy chunk
	regsub -all {[áÁàÀâÂãÃåÅ]} $chunk {a} chunk
	regsub -all {[çÇ]} $chunk {c} chunk
	regsub -all {[éÉèÈêÊëË]} $chunk {e} chunk
	regsub -all {[íÍìÌîÎïÏ]} $chunk {i} chunk
	regsub -all {[ñÑ]} $chunk {n} chunk
	regsub -all {[óÓòÒôÔõÕøØöÖ]} $chunk {o} chunk
	regsub -all {[úÚùÚû?üÜ]} $chunk {u} chunk
	regsub -all {[ÿÙ]} $chunk {y} chunk
	regsub -all {[æÆäÄ]} $chunk {ae} chunk
	regsub -all {[ÎÏ]} $chunk {oe} chunk

	regsub -all {[^A-Za-z ]} $chunk {} chunk
	return [string tolower $chunk]
}

proc formatOutput { linje } {
	# FORMATTING --- clean up / recover the original formatting
	regsub -all " <hw>" $linje "\r* " linje
	regsub -all "<hw>" $linje "* " linje
	regsub -all {<pos>([0-9]+)</pos>} $linje {} linje
	regsub -all {<pos>([^<]+)</pos>} $linje {(\1) } linje
	regsub -all {<[^<>]+>} $linje "" linje

	set lineList [split $linje \r]
        set pL [list ]
	foreach p $lineList {
		lappend pL [breakIntoLines $p]
	}
	set linje [join $pL \r]
        regsub -all \r\r $linje \r linje

	return $linje
}

END TCL -->

