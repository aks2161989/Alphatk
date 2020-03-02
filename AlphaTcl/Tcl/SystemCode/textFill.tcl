## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "windows.tcl"
 #                                          created: 11/26/1996 {07:08:34 pm} 
 #                                      last update: 03/21/2006 {01:01:27 PM}
 # Description:
 # 
 # Procedures that deal specifically with windows that have already been 
 # created by the core.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 1996-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc textFill.tcl {} {}

proc getEndpts {} {
    if {[pos::compare [getPos] == [selEnd]]} {
	set start [getPos]
	set finish [getPin]
	if {[pos::compare $start > $finish]} {
	    set temp $start
	    set start $finish
	    set finish $temp
	}
    } else {
	set start [getPos]
	set finish [selEnd]
    }
    return [list $start $finish]
}

# To be removed soon
proc fillRegion {} {
    if {![win::checkIfWinToEdit]} {return}
    global leftFillColumn
    set ends [getEndpts]
    set start [lineStart [lindex $ends 0]]
    set finish [lindex $ends 1]
    goto $start
    set text [fillText $start $finish]
    replaceText $start $finish [format "%$leftFillColumn\s" ""] $text "\r"
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "wrapText" --  ?-w <windowName>? pos0 pos1
 # 
 # Given two valid window positions (using the active window by default),
 # wrap each line found between them respecting the current "fillColumn"
 # value.  If there are any changes to be made, replace the text all at once
 # to allow a single [undo] to restore the original.  This makes absolutely
 # no attempt to deal with comments, [paragraph::fill] is better suited for
 # that purpose.
 # 
 # This returns a two-item list, containing the number of lines found in the
 # original region, and the number of new lines which were inserted.
 # 
 # (Prior to Alpha8/X 8.0b8-D6 and Alphatk 8.3f6, this was a core command.)
 # 
 # --------------------------------------------------------------------------
 ##

proc wrapText {args} {
    
    win::parseArgs w pos0 pos1
    
    if {[catch {win::getModeVar $w fillColumn} fc]} {
	return
    } 
    set pos0 [pos::lineStart -w $w $pos0]
    set pos1 [pos::lineEnd -w $w $pos1]
    set count0 -1
    set count1 0
    if {[pos::compare -w $w $pos1 == [pos::max -w $w]]} {
	set pos1 [pos::max -w $w]
	incr count0
    } elseif {[pos::compare -w $w [pos::lineStart -w $w $pos1] < $pos1]} {
	set pos1 [pos::nextLineStart -w $w $pos1]
    }
    set newLines [list]
    foreach line [split [getText -w $w $pos0 $pos1] "\r\n"] {
	incr count0
	if {([string length $line] <= $fc) || ![regexp -- {[\t ]} $line]} {
	    lappend newLines $line
	    continue
	} 
	while {([string length $line] > $fc)} {
	    set foundBreak 0
	    # Look for whitespace to break preceding the "fillColumn" column.
	    set limit [expr {$fc + 1}]
	    for {set i 1} {($i < $limit)} {incr i 1} {
		set idx [expr $fc - $i]
		if {[regexp -- {[\t ]} [string index $line $idx]]} {
		    set newLine [string trimright [string range $line 0 $idx]]
		    lappend newLines $newLine
		    set line [string trimleft [string range $line $idx end]]
		    set foundBreak 1
		    incr count1
		    break
		} 
	    }
	    if {$foundBreak} {
		if {([string length $line] <= $fc)} {
		    lappend newLines $line
		    break
		} else {
		    continue
		}
	    } 
	    # Still here?  Look for whitespace after the "fillColumn" column.
	    set limit [string length $line]
	    for {set idx [expr {$fc - 1}]} {($idx < $limit)} {incr idx 1} {
		if {[regexp -- {[\t ]} [string index $line $idx]]} {
		    set newLine [string trimright [string range $line 0 $idx]]
		    lappend newLines $newLine
		    set line [string trimleft [string range $line $idx end]]
		    set foundBreak 1
		    incr count1
		    break
		} 
	    }
	    if {!$foundBreak || ([string length $line] <= $fc)} {
		lappend newLines $line
		break
	    } 
	}
    }
    if {$count1} {
	replaceText -w $w $pos0 $pos1 [join $newLines "\r"]
    } 
    return [list $count0 $count1]
}

##
 # --------------------------------------------------------------------------
 # 
 # "wrapParagraph" --  ?-w <windowName>?
 # 
 # Using current selection information (from the active window by default),
 # wrap each line in either the selection or the paragraph containing the
 # cursor, and display the results of any changes in the status bar.
 # 
 # --------------------------------------------------------------------------
 ##

proc wrapParagraph {args} {
    
    win::parseArgs w
    
    if {![win::checkIfWinToEdit $w]} {
	return
    } 
    set p [getPos -w $w]
    if {![set reselect [isSelection -w $w]]} {
	set p0 [paragraph::start -w $w $p]
	set p1 [paragraph::finish -w $w $p]
    } else {
	set p0 $p
	set p1 [selEnd -w $w]
    }
    set counts [wrapText -w $w $p0 $p1]
    if {$reselect && ![isSelection -w $w]} {
	selectText -w $w $p [getPos -w $w]
    } 
    if {([set count0 [lindex $counts 0]] == 1)} {
	append msg "1 original line, "
    } else {
	append msg "$count0 original lines, "
    }
    if {([set count1 [lindex $counts 1]] == 1)} {
	append msg "1 additional line created."
    } else {
	append msg "$count1 additional lines created."
    }
    status::msg $msg
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "wrapRegion" --  ?-w <windowName>?
 # 
 # If there is a selection (in the active window by default), wrap each line
 # in it, otherwise inform the user why nothing was done.  This used to be
 # called by a "Text > Wrap Region" menu item that has since been removed,
 # and is now just a wrapper to call [wrapParagraph].
 # 
 # --------------------------------------------------------------------------
 ##

proc wrapRegion {args} {
    
    win::parseArgs w
    
    if {![win::checkIfWinToEdit $w]} {
	return
    } 
    if {![isSelection -w $w]} {
	status::msg "This item requires a selection."
    } else {
	wrapParagraph -w $w
    }
    return
}


# Remove text from window, transform, and insert back into window.
proc fillText {from to} {
    global doubleSpaces
    set text [getText $from $to]
    regexp "^\[ \t\]*" $text front
    regsub -all "\[ \t\n\r\]+" [string trim $text] " " text
    if {$doubleSpaces} {regsub -all {(([^.][a-z]|[^a-zA-Z@]|\\@)[.?!]("|'|'')?([])])?) } $text {\1  } text}
    regsub -all " ?\[\r\n\]" [string trimright [breakIntoLines $text]] "\r${front}" text
    return $front$text
}

##
 # --------------------------------------------------------------------------
 # 
 # "paragraphToLine" --
 # 
 # Remove all line ending characters in each paragraph within the selected
 # region, or in the current paragraph if there is no selection.  We use
 # the optional fourth argument to paragraph::fillOne to specify an 
 # infinite fill column.
 # 
 # --------------------------------------------------------------------------
 ##

proc paragraphToLine {} {
    if {![isSelection]} {
	paragraph::select
    }
    paragraph::fillOne 1 "" "" "infinite"
    return
}

proc lineToParagraph {} {
    if {![isSelection]} {
	selectText [pos::lineStart] [pos::lineEnd]
    }
    paragraph::fill
    return
}

# A sentence is defined to begin at the first occurrence of $sentBeg
# which comes after a $sentEnd:
# set sentEnd {(\r[\r\n\t ]*\r|\n\n|[.!?](\r|\n| +))}
set sentEnd {(\r[\r\n\t ]*\r|\n\n|[.!?][])\}"]*(\r|\n| +))}
set sentBeg {[\r\n ][[\{("]*[A-ZÁÀÂÃÅÆÄÇÉÈÊËÍÌÎÏÑÓÒÔÕØÖ^ÑÚÛÜÙ^Í]}
# Note that these regexps are designed for old-style Tcl (Alpha 7)
# In newer Tcl perhaps some backslashes should be removed...

proc prevSentence {} {
    global sentBeg sentEnd
    # look back for a $sentBeg:
    if {[catch {search -s -f 0 -r 1 -i 0 $sentBeg \
      [pos::math [getPos] - 3]} mtch]} {
	if {[regexp -- {[A-ZÁÀÂÃÅÆÄÇÉÈÊËÍÌÎÏÑÓÒÔÕØÖ^ÑÚÛÜÙ^Í]} \
	  [lookAt [minPos]]] } {
	    # special case of sentence starting at file start
	    goto [minPos]
	    status::msg "Previous sentence"
	    return
	}
	# didn't find any...
	status::msg "No previous sentence found..."
	return
    }
    # look further back for $sentEnd:
    if {[catch {search -s -f 0 -r 1 $sentEnd \
      [pos::math [lindex $mtch 0] + 1]} mtch]} {
	# didn't find any, so use file start:
	set mtch [list [minPos] [pos::math [minPos] +1 ]]
    }
    # look forward for $sentBeg (we know for sure it exists...)
    if {[catch {search -s -f 1 -r 1 -i 0 $sentBeg \
      [pos::math [lindex $mtch 1] - 1]} mtch]} {
	# we should never get in here...
	status::msg "What happened?"
    }
    # finally, go to the position we found:
    goto [pos::math [lindex $mtch 1] - 1]
    status::msg "Previous sentence"
    return
}

proc nextSentence {} {
    global sentBeg sentEnd
    # look forth for $sentEnd:
    if {[catch {search -s -f 1 -r 1 $sentEnd [getPos]} mtch]} {
	# didn't find any...
	status::msg "No next sentence found..."
	return
    }
    if {[catch {search -s -f 1 -r 1 -i 0 $sentBeg \
      [pos::math [lindex $mtch 1] - 1]} mtch]} {
	# didn't find any...
	status::msg "No next sentence found..."
	return
    }
    # go to the position we found:
    goto [pos::math [lindex $mtch 1] - 1]
    status::msg "Next sentence"
    return
}

# ===========================================================================
# 
# .