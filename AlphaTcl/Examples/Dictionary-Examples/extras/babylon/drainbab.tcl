# This proc is for extracting plain text from babylon dictionary files.
# It works by running through a wordlist and looking up all the words in
# the babylon file one by one, using the command line programme of 
# F. Jolliton, and writing the result to a new file with minimal markup.
# (In order to work, the file norm.tcl and the programme babylon should 
# be located in the same folder as this script... Download the programme
# from http://fjolliton.free.fr/babytrans/babylon-c.tgz )
# 
# Syntax:  wList is the name of a wordlist file
#          targetLanguage is the name of a babylon file (eg. EngtoFre.dic)
# A new file is produced, with the name (eg.) EngtoFre.dictionary


proc drain { wList targetLanguage } {
	
	set wordList [open $wList r]
	
															set currCh a
															puts -nonewline "Progress: $currCh"
															flush stdout
	while { [gets $wordList key] > 0 } { 
		set key [string trim $key]

															set ch [string tolower [string range $key 0 0]]
															if { $ch != $currCh } {
																if { [regexp {[a-z]} $ch] } {
																	set currCh $ch
																	puts -nonewline $currCh
																	flush stdout
																}
															}

		catch { exec ./babylon english.dic $targetLanguage $key } res
		regsub -- "child process exited abnormally" $res "" res
		if { [string length $res] == 0 } {
			continue
		}
		if { [regexp -- {Invalid word} $res] } {
			continue
		}
		
		while { [regexp -- {__([^_]+) \(([^\)]+)\)__\n([^_]*)} $res dummy et to tre] } {
			regsub -- {__([^_]+) \(([^\)]+)\)__\n([^_]*)} $res "" res
			
			set thisres "<hw>$et</hw> <pos>$to</pos> <trad>$tre</trad>"
			regsub -all {\n\n} $thisres {} thisres
			regsub -all {\n} $thisres {, } thisres
			# 		regsub -all {, <} $thisres { } thisres
			# 		regsub -all {[^>]{5}0000} $thisres "abr." thisres
			
			regsub -all {\?\(} $thisres {? (} thisres
			regsub -all {!\(} $thisres {! (} thisres
			regsub -all {\?([^, <])} $thisres {?, \1} thisres
			regsub -all {!([^, <])} $thisres {!, \1} thisres
			if { [regexp -- {<trad></trad>} $thisres] } {
				continue 
			}
			
			lappend L $thisres
		}
		
	}
	close $wordList
	
															puts ""
															puts "Sorting..."
															flush stdout
	set LL [lsort -unique $L]
	set LLL [lsort -command specialCompare $LL]


	set out [open ${targetLanguage}tionary a]
	set preambleFile [open norm.tcl r]
	puts $out [read $preambleFile]
	close $preambleFile
	
															puts "Writing..."
															flush stdout

	set prevLine ""
	set prevHead ""
	foreach line $LLL {
		regexp -- {<hw>(.*)</hw>} $line head
		if { [string compare $head $prevHead] == 0 } {
			puts -nonewline $out "$prevLine "
		} else {
			puts $out $prevLine
		}
		set prevLine $line
		set prevHead $head  
	}
	puts $out $prevLine
	
	close $out
}

proc specialCompare { one two } { 
	return [string compare [specialForm $one] [specialForm $two]]
}

proc specialForm { ord } {
  regexp -- {<hw>(.*)</hw> <pos>(.*)</pos>} $ord dummy head gram

	regsub -all {[áÁàÀâÂãÃåÅ]} $head {a} head
	regsub -all {[çÇ]} $head {c} head
	regsub -all {[éÉèÈêÊëË]} $head {e} head
	regsub -all {[íÍìÌîÎïÏ]} $head {i} head
	regsub -all {[ñÑ]} $head {n} head
	regsub -all {[óÓòÒôÔõÕøØöÖ]} $head {o} head
	regsub -all {[úÚùÚû?üÜ]} $head {u} head
	regsub -all {[ÿÙ]} $head {y} head
	regsub -all {[æÆäÄ]} $head {ae} head
	regsub -all {[ÎÏ]} $head {oe} head
	regsub -all {[^A-Za-z ]} $head {} head
	set head [string tolower $head]

	regsub {n\.} $gram A gram
	regsub {v\.} $gram B gram
	regsub {a\.} $gram C gram
	regsub {adv\.} $gram D gram
	regsub {[0-9]+} $gram E gram

	return $head$gram
}
