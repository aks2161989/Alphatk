# -*-tcl-*- nowrap

# This code is to be inserted in the beginning 
# of a babylon dictionary file

<!-- BEGIN TCL
	
# This proc takes the first word of the input string
# strips all accents,
# and then removes all non-alpha letters
proc normalForm { chunk } {
  regexp {^<hw>([^<]+)</hw>} $chunk dummy chunk
	regsub -all {[����������]} $chunk {a} chunk
	regsub -all {[��]} $chunk {c} chunk
	regsub -all {[��������]} $chunk {e} chunk
	regsub -all {[��������]} $chunk {i} chunk
	regsub -all {[��]} $chunk {n} chunk
	regsub -all {[������������]} $chunk {o} chunk
	regsub -all {[�����?��]} $chunk {u} chunk
	regsub -all {[��]} $chunk {y} chunk
	regsub -all {[����]} $chunk {ae} chunk
	regsub -all {[��]} $chunk {oe} chunk

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

